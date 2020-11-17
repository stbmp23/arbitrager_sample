# frozen_string_literal: true

require 'arbitrager/order'

module Arbitrager
  module Orders
    class Quoinex < Arbitrager::Order
      def initialize(order_type, price, volume)
        super(Arbitrager.brokers.quoinex.code, order_type, price, volume)
      end

      # 買い注文を作成する
      #
      # @return [Arbitrager::Order]
      def self.create_ask(price, volume)
        self.new(:ask, price, volume)
      end

      # 売り注文を作成する
      #
      # @return [Arbitrager::Order]
      def self.create_bid(price, volume)
        self.new(:bid, price, volume)
      end

      # 買い板に対して、売り注文を出す
      def send_ask_request!
        super { |response|
          response['id']
        }
      end

      # 売り板に対して、買い注文を出す
      def send_bid_request!
        super { |response|
          response['id']
        }
      end

      # 売り注文に対して反対売買を実行する
      def send_reverse_ask_request!
        super { |response|
          response['id']
        }
      end

      # 買い注文に対して反対売買を実行する
      def send_reverse_bid_request!
        super { |response|
          response['id']
        }
      end

      # 注文が約定したかどうか
      def execution?
        super { |order_id|
          response = client.get_order(order_id)
          return false unless response.valid?

          order = response.params
          order['status'] == 'filled' ? true : false
        }
      end

      # 注文をキャンセルする
      def cancel_request!
        super { |response| true }
      end

      # 注文履歴一覧から注文内容を更新する
      def update_execution
        super { |order_id|
          params = {
            price: 0,
            volume: 0,
            fee: 0
          }

          response = client.get_order(order_id)
          return false unless response.valid?

          order = response.params
          params[:fee] = order['order_fee']

          order['executions'].each do |execution|
            params[:price] += execution['price'].to_f
            params[:volume] += execution['quantity'].to_f
          end

          params
        }
      end
    end
  end
end
