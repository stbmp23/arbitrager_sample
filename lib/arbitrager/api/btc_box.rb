# frozen_string_literal: true

require 'arbitrager/api/concern'
require 'arbitrager/api/response'
require 'arbitrager/api/validator/btc_box'

module Arbitrager
  module Api
    class BtcBox
      include Arbitrager::Api::Concern

      ENDPOINT_URL = 'https://www.btcbox.co.jp'

      attr_reader :client

      def initialize
        @client =  Arbitrager::Api::Client.new(ENDPOINT_URL)
      end

      # 板情報を取得する
      def order_books
        send_request(:order_books, METHOD_GET, '/api/v1/depth/')
      end

      # 注文を作成する
      def send_order(action, price, volume)
        params = {
          amount: volume,
          price: price,
          type: action,
        }

        send_private_request(:send_order, METHOD_POST, '/api/v1/trade_add/', params)
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
        params = { type: 'all' }
        params[:since] = options[:since] if options[:since].present?

        send_private_request(:get_orders, METHOD_POST, '/api/v1/trade_list/', params)
      end

      # 注文を1件取得する
      def get_order(target_order_id)
        send_private_request(:get_order, METHOD_POST, '/api/v1/trade_view/', {
          id: target_order_id,
        })
      end

      # 注文の一覧を取得する(未約定注文一覧)
      def get_active_orders(options = {})
        params = { type: 'part' }
        params[:since] = options[:since] if options[:since].present?

        get_orders(params)
      end

      # 注文を1件取得する(未約定注文)
      def get_active_order(target_order_id)
        response = get_order(target_order_id)
        return false unless response.valid?

        order = response.params
        order['status'] == 'part' ? order : nil
      end

      # 注文をキャンセルする
      def cancel_order(order_id)
        send_private_request(:cancel_order, METHOD_POST, '/api/v1/trade_cancel/', {
          id: order_id,
        })
      end

      # 総資産の一覧を取得する
      def get_balance
        send_private_request(:get_balance, METHOD_POST, '/api/v1/balance/')
      end

      private

      # Public API用リクエスト送信
      def send_request(method_code, method, path, query = nil, header = nil)
        response = client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::BtcBox.new(method_code))
      end

      # Private API用リクエスト送信
      def send_private_request(method_code, method, path, query = nil)
        params = request_params(query)
        send_request(method_code, method, path, params)
      end

      # リクエストヘッダー作成
      def request_params(query)
        nonce = DateTime.now.strftime('%Q')

        params = query || {}
        params.merge!({
          'nonce' => nonce,
          'key' => Arbitrager.brokers.btcbox.key,

        })
        params['signature'] = signature(params)

        params
      end

      # 認証トークン作成
      def signature(query)
        secret = Digest::MD5.hexdigest(Arbitrager.brokers.btcbox.secret)
        text = query.to_query

        OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, secret, text)
      end
    end
  end
end
