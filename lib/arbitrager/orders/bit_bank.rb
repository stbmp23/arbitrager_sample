# frozen_string_literal: true

require 'arbitrager/order'

module Arbitrager
  module Orders
    class BitBank < Arbitrager::Order
      def initialize(order_type, price, volume)
        super(Arbitrager.brokers.bitbank.code, order_type, price, volume)
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
          response['data']['order_id']
        }
      end

      # 売り板に対して、買い注文を出す
      def send_bid_request!
        super { |response|
          response['data']['order_id']
        }
      end

      # 売り注文に対して反対売買を実行する
      def send_reverse_ask_request!
        super { |response|
          response['data']['order_id']
        }
      end

      # 買い注文に対して反対売買を実行する
      def send_reverse_bid_request!
        super { |response|
          response['data']['order_id']
        }
      end

      # 注文が約定したかどうか
      def execution?
        super { |order_id|
          response = client.get_order(order_id)
          return false unless response.valid?

          order = response.params['data']
          order['status'] == 'FULLY_FILLED' ? true : false
        }
      end

      # 注文をキャンセルする
      def cancel_request!
        super { |response|
          params = response.params
          if params['success'] == Arbitrager::Api::Validator::BitBank::RESPONSE_SUCCESS
            true
          elsif params['data'].present? && params['data']['code'].present? && params['data']['code'].to_i == 50009
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

          response = client.get_order(order_id)
          return false unless response.valid?

          order = response.params['data']
          params[:price] = order['average_price'].to_f
          params[:volume] = order['executed_amount'].to_f

          params
        }
      end
    end
  end
end
