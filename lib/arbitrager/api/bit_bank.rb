# frozen_string_literal: true

require 'arbitrager/api/concern'
require 'arbitrager/api/response'
require 'arbitrager/api/validator/bit_bank'

module Arbitrager
  module Api
    class BitBank
      include Arbitrager::Api::Concern

      ENDPOINT_URL_PUBLIC = 'https://public.bitbank.cc'
      ENDPOINT_URL_PRIVATE = 'https://api.bitbank.cc'
      PRODUCT_CODE = 'btc_jpy'

      attr_reader :public_client, :private_client

      def initialize
        @public_client =  Arbitrager::Api::Client.new(ENDPOINT_URL_PUBLIC)
        @private_client =  Arbitrager::Api::Client.new(ENDPOINT_URL_PRIVATE)
      end

      # 板情報を取得する
      def order_books
        send_request(:order_books, METHOD_GET, "/#{PRODUCT_CODE}/depth")
      end

      # 注文を作成する
      def send_order(action, price, volume)
        params = {
          pair: PRODUCT_CODE,
          type: 'limit', # 指値: limit, 成行: market
          price: price,
          side: action,
          amount: volume,
        }

        send_private_request(:send_order, METHOD_POST, '/v1/user/spot/order', params)
      end

      # 買い注文を出す
      def send_order_ask(price, volume)
        send_order('buy', price, volume)
      end

      # 売り注文を出す
      def send_order_bid(price, volume)
        send_order('sell', price, volume)
      end

      # 注文の一覧を取得する
      def get_orders_info(order_ids)
        send_private_request(:get_orders, METHOD_POST, '/v1/user/spot/orders_info', {
          pair: PRODUCT_CODE,
          order_ids: order_ids,
        })
      end

      # 注文の一覧を取得する
      def get_orders
        send_private_request(:get_orders, METHOD_GET, '/v1/user/spot/trade_history')
      end

      # 注文を1件取得する
      def get_order(target_order_id)
        send_private_request(:get_order, METHOD_GET, '/v1/user/spot/order', {
          pair: PRODUCT_CODE,
          order_id: target_order_id,
        })
      end

      # 注文の一覧を取得する(未約定注文一覧)
      def get_active_orders(options = {})
        send_private_request(:get_active_orders, METHOD_GET, '/v1/user/spot/active_orders', {
          pair: PRODUCT_CODE,
        })
      end

      # 注文を1件取得する(未約定注文)
      def get_active_order(target_order_id)
        response = get_order(target_order_id)
        return false unless response.valid?

        order = response.params['data']
        order['status'] == 'UNFILLED' || order['status'] == 'PARTIALLY_FILLED' ? order : nil
      end

      # 注文をキャンセルする
      def cancel_order(order_id)
        send_private_request(:cancel_order, METHOD_POST, '/v1/user/spot/cancel_order', {
          pair: PRODUCT_CODE,
          order_id: order_id,
        })
      end

      # 総資産の一覧を取得する
      def get_balance
        send_private_request(:get_balance, METHOD_GET, '/v1/user/assets')
      end

      private

      # Public API用リクエスト送信
      def send_request(method_code, method, path, query = nil, header = nil)
        response = public_client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::BitBank.new(method_code))
      end

      # Private API用リクエスト送信
      def send_private_request(method_code, method, path, query = nil)
        header = request_header(method, path, query)
        query = query.to_json if method == METHOD_POST && query
        response = private_client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::BitBank.new(method_code))
      end

      # リクエストヘッダー作成
      def request_header(method, path, query)
        nonce = DateTime.now.strftime('%Q')

        {
          'ACCESS-KEY' => Arbitrager.brokers.bitbank.key,
          'ACCESS-NONCE' => nonce,
          'ACCESS-SIGNATURE' => signature(method, path, query, nonce),
          'Content-Type' => 'application/json',
        }
      end

      # 認証トークン作成
      def signature(method, path, query, nonce)
        secret = Arbitrager.brokers.bitbank.secret

        text = nonce.to_s
        if method == METHOD_GET
          text += path
          text += "?#{query.to_query}" if query
        elsif method == METHOD_POST
          text += query.to_json
        end

        OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, secret, text)
      end
    end
  end
end
