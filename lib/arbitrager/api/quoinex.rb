# frozen_string_literal: true

require 'arbitrager/api/response'
require 'arbitrager/api/validator/quoinex'

module Arbitrager
  module Api
    class Quoinex
      include Arbitrager::Api::Concern

      ENDPOINT_URL = 'https://api.quoine.com'
      PRODUCT_CODE = 'BTCJPY'
      PRODUCT_ID = 5  # BTCJPYのproduct_id

      attr_reader :client

      def initialize
        @client = Arbitrager::Api::Client.new(ENDPOINT_URL)
      end

      # 通貨ペア確認用
      def products
        send_request(:products, METHOD_GET, '/products')
      end

      # 板情報を取得する
      def order_books
        send_request(:order_books, METHOD_GET, "/products/#{PRODUCT_ID}/price_levels")
      end

      # 注文を作成する
      def send_order(action, price, volume)
        params = {
          order_type: 'market',
          procut_id: PRODUCT_ID,
          side: action,
          quantity: volume,
        }

        send_private_request(:send_order, METHOD_POST, '/orders/', params)
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
      def get_orders(options = {})
        send_private_request(:get_orders, METHOD_GET, '/orders', {
          product_id: PRODUCT_ID,
        })
      end

      # 注文を1件取得する
      def get_order(target_order_id)
        send_private_request(:get_order, METHOD_GET, "/orders/#{target_order_id}")
      end

      # 注文の一覧を取得する(未約定注文一覧)
      def get_active_orders
        send_private_request(:get_active_orders, METHOD_GET, '/orders', {
          product_id: PRODUCT_ID,
          status: 'live',
        })
      end

      # 注文を1件取得する(未約定注文)
      def get_active_order(target_order_id)
        order = get_order(target_order_id).params
        order['status'] == 'live' ? order : nil
      end

      # 注文をキャンセルする
      def cancel_order(order_id)
        send_private_request(:cancel_order, METHOD_PUT, "/orders/#{order_id}/cancel")
      end

      # 総資産の一覧を取得する
      def get_balance
        send_private_request(:get_balance, METHOD_GET, '/accounts/balance')
      end

      private

      # Public API用リクエスト送信
      def send_request(method_code, method, path, query = nil, header = nil)
        response = client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::Quoinex.new(method_code))
      end

      # Private API用リクエスト送信
      def send_private_request(method_code, method, path, query = nil)
        header = request_header(path, query)
        send_request(method_code, method, path, query, header)
      end

      # リクエストヘッダー作成
      def request_header(path, query)
        {
          'X-Quoine-API-Version' => '2',
          'X-Quoine-Auth' => signature(path, query),
          'Content-Type' => 'application/json',
        }
      end

      # 認証トークン作成
      def signature(path, query)
        path += '?' + query.to_param unless query.nil?

        auth_payload = {
          path: path,
          nonce: DateTime.now.strftime('%Q'),
          token_id: Arbitrager.brokers.quoinex.key,
        }
        secret = Arbitrager.brokers.quoinex.secret

        JWT.encode(auth_payload, secret, 'HS256')
      end
    end
  end
end
