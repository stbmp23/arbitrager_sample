# frozen_string_literal: true

require 'arbitrager/order'

module Arbitrager
  module Orders
    class Zaif < Arbitrager::Order
      attr_accessor :received, :remains

      def initialize(order_type, price, volume)
        super(Arbitrager.brokers.zaif.code, order_type, price, volume)
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
          response["return"]["order_id"]
        }
      end

      # 売り板に対して、買い注文を出す
      def send_bid_request!
        super { |response|
          response["return"]["order_id"]
        }
      end

      # 売り注文に対して反対売買を実行する
      def send_reverse_ask_request!
        super { |response|
          response["return"]["order_id"]
        }
      end

      # 買い注文に対して反対売買を実行する
      def send_reverse_bid_request!
        super { |response|
          response["return"]["order_id"]
        }
      end

      # 注文が約定したかどうか
      #
      # @return [true, false] 約定済みの場合 true
      def execution?
        super { |order_id|
          order = client.get_active_order(order_id)
          order_id == 0 || order.nil?
        }
      end

      # 注文をキャンセルする
      def cancel_request!
        super { |response|
          params = response.params
          if params['success'] == Arbitrager::Api::Validator::Zaif::RESPONSE_SUCCESS
            true
          elsif params.has_key?('error') && params['error'] == 'order not found'
            true
          else
            false
          end
        }
      end

      # 注文履歴一覧から注文内容を更新する
      def update_execution
        super { |order_id|
          params = {
            price: 0,
            volume: 0,
            fee: 0
          }

          response = client.get_orders({ since: model.started_at.to_i })
          return false unless response.valid?

          response.params['return'].each do |id, order|
            # Zaifの場合はアクションが逆になっている
            action_code = model.action_code == :ask ? 'bid' : 'ask'
            next if order['your_action'] != action_code

            params[:price] = order['price']
            params[:volume] += order['amount']
            params[:fee] += order['fee']
          end

          params
        }
      end
    end
  end
end
