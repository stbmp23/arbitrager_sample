# frozen_string_literal: true

module Arbitrager
  class Order
    attr_reader :broker, :model, :client, :reverse_order

    def initialize(broker_code, order_type, price, volume)
      @broker = Arbitrager.brokers.get(broker_code)
      @model = Arbitrager::Models::Order.new({
        broker_id: broker.id,
        action_id: Settings.actions[order_type].id,
        target_price: price,
        target_volume: volume,
        started_at: Time.now,
      })
      @client = Arbitrager.clients.get(broker_code)
    end

    # 反対注文時の価格を計算する
    #
    # @return [Float]
    def reverse_price
      limit_move_percent = Settings.limit_move_percent
      add_price = model.target_price * (limit_move_percent.to_f / 100.0)
      # 購入が5円単位になるように調整
      add_price -= add_price % 5

      if model.ask?
        model.target_price + add_price
      elsif model.bid?
        model.target_price - add_price
      end
    end

    # APIに注文リクエストを送信する
    #
    # @return [true, false]
    def send_request!
      if model.ask?
        result = send_ask_request!
      elsif model.bid?
        result = send_bid_request!
      end

      model.result = result
    rescue Faraday::Error::TimeoutError => e
      Arbitrager.logger.error(e)
      return false
    rescue Arbitrager::Error::ApiResponseError => e
      Arbitrager.logger.error(e)
      return false
    end

    # 確定済みの注文に対して反対注文を出す
    #
    # @return [true, false]
    def send_reverse_request!
      Arbitrager.logger.info("Order:　反対売買(#{broker.code})")
      klass = "Arbitrager::Orders::#{broker.name.classify}".constantize

      if model.ask?
        @reverse_order = klass.create_bid(reverse_price, model.target_volume)
      elsif model.bid?
        @reverse_order = klass.create_ask(reverse_price, model.target_volume)
      end

      reverse_order.model.reverse_order_flg = true
      reverse_order.send_request!

      reverse_order.model.result
    rescue Faraday::Error::TimeoutError => e
      Arbitrager.logger.error(e)
      return false
    rescue Arbitrager::Error::ApiResponseError => e
      Arbitrager.logger.error(e)
      return false
    end

    # 注文が約定したかどうか
    #
    # @return [true, false]
    def execution?
      raise "order_id is nil." if model.order_acceptance_id.nil?
      Arbitrager.logger.info("Order: 約定確認(#{broker.code})")

      return true if model.execution_flg

      model.execution_flg = yield(model.order_acceptance_id)
    rescue Faraday::Error::TimeoutError => e
      Arbitrager.logger.error(e)
      return false
    rescue Arbitrager::Error::ApiResponseError => e
      Arbitrager.logger.error(e)
      return false
    end

    # キャンセル注文を出す
    #
    # @return [true, false]
    def cancel_request!
      Arbitrager.logger.info("Order: キャンセル(#{broker.code})")
      raise "order_id is nil." if model.order_acceptance_id.nil?

      response = client.cancel_order(model.order_acceptance_id)
      return false unless response.valid?

      result = yield(response)

      model.canceled_at = Time.now if result
      model.cancel_flg = result
    rescue Faraday::Error::TimeoutError => e
      Arbitrager.logger.error(e)
      return false
    rescue Arbitrager::Error::ApiResponseError => e
      Arbitrager.logger.error(e)
      return false
    end

    # 注文を元戻す(キャンセルして反対売買する)
    def rollback!
      Arbitrager.logger.info("Order: ロールバックの実行(#{broker.code})")
      if execution?
        retry_request(5) { send_reverse_request! }
      else
        retry_request(10) { cancel_request! }
      end
    end

    # 注文履歴一覧から注文内容を更新する
    def update_execution
      Arbitrager.logger.info("Order: 注文履歴の更新(#{broker.code})")
      params = yield(model.order_acceptance_id)

      return false unless params.is_a?(Hash)

      model.attributes = {
        price: params[:price],
        volume: params[:volume],
        fee: params[:fee],
      }

      true
    rescue Faraday::Error::TimeoutError => e
      Arbitrager.logger.error(e)
      return false
    rescue Arbitrager::Error::ApiResponseError => e
      Arbitrager.logger.error(e)
      return false
    end

    # 注文履歴一覧から注文内容を更新する
    # (更新完了まで待つ)
    def update_execution!
      start_time = Time.now
      until update_execution
        if Time.now - start_time >= Settings.wait_for_execution_time
          Arbitrager.logger.warn('update_executionの実行に失敗しました')
          return false
        end

        Settings.wait_for_send_order_retry_time
      end

      true
    end

    private

    # 売り板に対して、買い注文を出す
    #
    # @return [true, false]
    def send_ask_request!
      message = "API実行: #{broker.name} [#{model.target_price}, #{model.target_volume}] (買い注文)"
      response = client.send_order_ask(model.target_price, model.target_volume)
      return false unless response.valid?

      model.response = response.body
      Arbitrager.logger.info("#{message}, 実行結果: #{response.body}")

      model.order_acceptance_id = yield(response.params)

      true
    end

    # 買い板に対して、売り注文を出す
    #
    # @return [true, false]
    def send_bid_request!
      message = "API実行: #{broker.name} [#{model.target_price}, #{model.target_volume}] (売り注文)"
      response = client.send_order_bid(model.target_price, model.target_volume)
      return false unless response.valid?

      model.response = response.body
      Arbitrager.logger.info("#{message}, 実行結果: #{response.body}")

      model.order_acceptance_id = yield(response.params)

      true
    end

    # リトライする
    #
    # @params [Integer] count リトライ回数
    # @return [true, false] 実行結果(成功の場合 true)
    def retry_request(count)
      count.times {
        if result = yield
          return result
        end
      }
      false
    end
  end
end
