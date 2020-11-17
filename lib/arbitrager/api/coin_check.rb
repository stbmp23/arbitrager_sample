# frozen_string_literal: true

require 'arbitrager/api/response'
require 'arbitrager/api/validator/coin_check'

module Arbitrager
  module Api
    class CoinCheck
      include Arbitrager::Api::Concern

      ENDPOINT_URL = 'https://coincheck.com'
      PRODUCT_CODE = 'btc_jpy'

      attr_reader :client

      def initialize
        @client = Arbitrager::Api::Client.new(ENDPOINT_URL)
      end

      # 板情報を取得する
      def order_books
        send_request(:order_books, METHOD_GET, '/api/order_books')
      end

      # 注文を作成する
      def send_order(action, price, volume)
        params = {
          pair: PRODUCT_CODE,
          order_type: action,
        }

        if action == 'market_buy'
          params[:market_buy_amount] = price * volume
        elsif action == 'market_sell'
          params[:amount] = volume
        end

        send_private_request(:send_order, METHOD_POST, '/api/exchange/orders', params.to_query)
      end

      # 買い注文を出す
      def send_order_ask(price, volume)
        send_order('market_buy', price, volume)
      end

      # 売り注文を出す
      def send_order_bid(price, volume)
        send_order('market_sell', price, volume)
      end

      # 注文の一覧を取得する
      def get_orders
        send_private_request(:get_orders, METHOD_GET, '/api/exchange/orders/transactions')
      end

      # 注文を取得する(指定ID)
      #
      # @return [Array, false]
      def get_order(order_id)
        response = get_orders
        return false unless response.valid?
        response.params['transactions'].select{ |order| order["order_id"].to_s == order_id.to_s }
      end

      # 注文の一覧を取得する(未約定)
      def get_active_orders
        send_private_request(:get_active_orders, METHOD_GET, '/api/exchange/orders/opens')
      end

      # 注文を取得する(注文ID)(未約定)
      #
      # @return [Array, false]
      def get_active_order(order_id)
        response = get_active_orders
        return false unless response.valid?
        response.params['orders'].select{ |order| order["id"].to_s == order_id.to_s }
      end

      # 注文をキャンセルする
      def cancel_order(order_id)
        send_private_request(:cancel_order, METHOD_DELETE, "/api/exchange/orders/#{order_id}")
      end

      # 総資産の一覧を取得する
      def get_balance
        send_private_request(:get_balance, METHOD_GET, '/api/accounts/balance')
      end

      private

      # Public API用リクエスト送信
      def send_request(method_code, method, path, query = nil, header = nil)
        response = client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::CoinCheck.new(method_code))
      end

      # Private API用リクエスト送信
      def send_private_request(method_code, method, path, query = nil)
        header = request_header(path)
        send_request(method_code, method, path, query, header)
      end

      # リクエストヘッダー作成
      def request_header(path)
        timestamp = Time.now.to_i.to_s

        {
          'ACCESS-KEY' => Arbitrager.brokers.coincheck.key,
          'ACCESS-NONCE' => timestamp,
          'ACCESS-SIGNATURE' => signature(path, timestamp),
          'Content-Type' => 'application/json',
        }
      end

      # 認証トークン作成
      def signature(path, timestamp)
        secret = Arbitrager.brokers.coincheck.secret
        uri = URI.join(ENDPOINT_URL, path)
        text = "#{timestamp}#{uri}"

        OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, secret, text)
      end
    end
  end
end
