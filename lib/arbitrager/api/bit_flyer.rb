# frozen_string_literal: true

require 'arbitrager/api/response'
require 'arbitrager/api/validator/bit_flyer'

module Arbitrager
  module Api
    class BitFlyer
      include Arbitrager::Api::Concern

      ENDPOINT_URL = 'https://api.bitflyer.jp'
      PRODUCT_CODE = 'BTC_JPY'

      attr_reader :client

      def initialize
        @client = Arbitrager::Api::Client.new(ENDPOINT_URL)
      end

      # 板情報を取得する
      def order_books
        send_request(:order_books, METHOD_GET, '/v1/getboard')
      end

      # 注文を作成する
      def send_order(action, price, volume)
        params = {
          product_code: PRODUCT_CODE,
          child_order_type: 'LIMIT',  # 指値: LIMIT, 成行: MARKET
          side: action,
          price: price, # 指値注文の場合は指定する
          size: volume,
          minutes_to_expire: 1000,
          time_in_force: 'GTC'
        }

        send_private_request(:send_order, METHOD_POST, '/v1/me/sendchildorder', params.to_json)
      end

      # 買い注文を出す
      def send_order_ask(price, volume)
        send_order('BUY', price, volume)
      end

      # 売り注文を出す
      def send_order_bid(price, volume)
        send_order('SELL', price, volume)
      end

      # 注文の一覧を取得する
      def get_orders(options = {})
        params = {
          product_code: PRODUCT_CODE,
        }
        params[:order_acceptance_id] = options[:order_acceptance_id] if options[:order_acceptance_id].present?
        params[:count] = options[:count] if options[:count].present?
        params[:before] = options[:before] if options[:before].present?
        params[:after] = options[:after] if options[:after].present?
        params[:child_order_state] = options[:child_order_state] if options[:child_order_state].present?

        send_private_request(:get_orders, METHOD_GET, '/v1/me/getchildorders', params)
      end

      # 注文を取得する
      #
      # @params [String] order_acceptance_id 注文ID
      # @return [Hash, nil] 注文情報
      def get_order(order_acceptance_id)
        response = get_orders(order_acceptance_id: order_acceptance_id)
        return nil unless response.valid?
        response.params.find{ |order| order["child_order_acceptance_id"].to_s == order_acceptance_id.to_s }
      end

      # 注文をキャンセルする(新規注文APIで受け取ったIDを指定する)
      def cancel_order(order_acceptance_id)
        params = {
          product_code: PRODUCT_CODE,
          child_order_acceptance_id: order_acceptance_id,
        }

        send_private_request(:cancel_order, METHOD_POST, '/v1/me/cancelchildorder', params.to_json)
      end

      # 総資産の一覧を取得する
      def get_balance
        send_private_request(:get_balance, METHOD_GET, '/v1/me/getbalance')
      end

      private

      # Public API用リクエスト送信
      def send_request(method_code, method, path, query = nil, header = nil)
        response = client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::Bitflyer.new(method_code))
      end

      # Private API用リクエスト送信
      def send_private_request(method_code, method, path, query = nil)
        header = request_header(path, method, query)
        send_request(method_code, method, path, query, header)
      end

      # リクエストヘッダー作成
      def request_header(path, method, query)
        timestamp = Time.now.to_i.to_s

        {
          'ACCESS-KEY' => Arbitrager.brokers.bitflyer.key,
          'ACCESS-TIMESTAMP' => timestamp,
          'ACCESS-SIGN' => signature(path, method, query, timestamp),
          'Content-Type' => 'application/json',
        }
      end

      # 認証トークン作成
      def signature(path, method, query, timestamp)
        secret = Arbitrager.brokers.bitflyer.secret
        text = "#{timestamp}#{method}#{path}"

        text += "?#{query.to_query}" if method == METHOD_GET && query
        text += query if method == METHOD_POST

        OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, secret, text)
      end
    end
  end
end
