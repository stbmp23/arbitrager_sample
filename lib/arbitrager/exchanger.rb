# frozen_string_literal: true

module Arbitrager
  class Exchanger
    attr_reader :bid_order, :ask_order, :model
    attr_reader :orders, :first_order, :second_order

    def initialize(bid_order, ask_order)
      @bid_order = bid_order
      @ask_order = ask_order
      @model = Arbitrager::Models::Exchange.new({
        target_benefit: Arbitrager.analyzer.target_position.target_profit_price,
      })

      @orders = sorted_orders
      @first_order = @orders[0]
      @second_order = @orders[1]
    end

    # 注文を実行優先順に並び替える
    #
    # @return [Array<Arbitrager::Order>] ソート後の注文一覧
    def sorted_orders
      [ask_order, bid_order].sort_by{ |order| order.broker.priority }
    end

    def start!
      Arbitrager.logger.info('取引を開始します')

      # 注文を出す
      # 1つめの注文が失敗したら、取引を中止する
      return false unless first_order.send_request!

      # もう片方は3回だけリトライする
      retry_count = 0
      until second_order.send_request!
        retry_count += 1

        if retry_count >= 10
          # 約定前だったらキャンセル注文を出す & 約定済みだったら反対注文を出す
          first_order.rollback!
          return response
        end

        sleep Settings.wait_for_send_order_retry_time
      end

      # 約定が完了するのを待つ
      start_time = Time.now
      until first_order.execution? && second_order.execution?
        sleep Settings.wait_for_send_order_retry_time

        if Time.now - start_time >= Settings.wait_for_execution_time
          # しばらく待っても片方しか約定しなかったら、キャンセルか反対売買を実行する
          first_order.rollback!
          second_order.rollback!

          break
        end
      end

      # 両オーダー共に約定済み
      model.result = true if first_order.execution? && second_order.execution?

      Arbitrager.logger.info('取引が完了しました')

      response
    end

    private

    # 取引内容を保存して結果を返す
    def response
      save_trades
      model.result
    end

    # DBへ取引内容を保存する
    def save_trades
      # 注文が完了しているものは約定情報を取得する
      orders.each do |order|
        order.update_execution! if order.model.result
        model.orders << order.model

        if order.reverse_order
          order.reverse_order.update_execution! if order.reverse_order.model.result
          model.orders << order.reverse_order.model
        end
      end

      # 利益を計算する
      model.orders.each do |order|
        revenue = order.ask? ? order.price * -1 : order.price
        model.benefit += revenue
      end

      model.save
    end
  end
end
