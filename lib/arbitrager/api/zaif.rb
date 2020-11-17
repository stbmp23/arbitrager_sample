# frozen_string_literal: true

require 'arbitrager/api/response'
require 'arbitrager/api/validator/zaif'

module Arbitrager
  module Api
    class Zaif
      include Arbitrager::Api::Concern

      ENDPOINT_URL = 'https://api.zaif.jp'
      PRODUCT_CODE = 'btc_jpy'

      attr_reader :client

      def initialize
        @client = Arbitrager::Api::Client.new(ENDPOINT_URL)
      end

      # 板情報を取得する
      #
      # @return [Arbitrager::Api::Response] APIレスポンス
      def order_books
        send_request(:order_books, METHOD_GET, '/api/1/depth/btc_jpy')
      end

      # 注文を作成する
      #
      # @params [String] action ask: 売り注文, bid: 買い注文
      # @params [Float] price 注文価格
      # @volume [Float] volume 注文数量
      # @return [Arbitrager::Api::Response] APIレスポンス
      def send_order(action, price, volume)
        params = {
          method: 'trade',
          nonce: nonce,
          currency_pair: PRODUCT_CODE,
          action: action,
          price: price.to_i,
          amount: volume,
        }

        send_private_request(:send_order, METHOD_POST, '/tapi', params.to_query)
      end

      # 買い注文を出す
      #
      # @params [Float] price 注文価格
      # @volume [Float] volume 注文数量
      # @return [Arbitrager::Api::Response] APIレスポンス
      def send_order_ask(price, volume)
        send_order('bid', price, volume)
      end

      # 売り注文を出す
      #
      # @params [Float] price 注文価格
      # @volume [Float] volume 注文数量
      # @return [Arbitrager::Api::Response] APIレスポンス
      def send_order_bid(price, volume)
        send_order('ask', price, volume)
      end

      # 注文の一覧を取得する
      #
      # @return [Arbitrager::Api::Response] APIレスポンス
      def get_orders(options = {})
        params = {
          method: 'trade_history',
          nonce: nonce,
          currency_pair: PRODUCT_CODE,
        }
        params[:from] = options[:from] if options[:from].present?
        params[:count] = options[:count] if options[:count].present?
        params[:from_id] = options[:from_id] if options[:from_id].present?
        params[:end_id] = options[:end_id] if options[:end_id].present?
        params[:order] = options[:order] if options[:order].present?
        params[:since] = options[:since] if options[:since].present?
        params[:end] = options[:end] if options[:end].present?

        send_private_request(:get_orders, METHOD_POST, '/tapi', params.to_query)
      end

      # 注文を1件取得する
      #
      # @param [Integer] target_order_id 注文ID
      # @return [Hash, nil] 注文情報
      def get_order(target_order_id)
        orders = get_orders.params
        return nil if !orders.is_a?(Hash) || orders['return'].blank?
        order = orders['return'].find{ |order_id, order| order_id.to_i == target_order_id.to_i }

        order.nil? ? nil : order[1]
      end

      # 注文の一覧を取得する(未約定注文一覧)
      #
      # @return [Arbitrager::Api::Response] APIレスポンス
      def get_active_orders
        send_private_request(:get_active_orders, METHOD_POST, '/tapi', {
          method: 'active_orders',
          nonce: nonce,
          currency_pair: PRODUCT_CODE,
        }.to_query)
      end

      # 注文を1件取得する(未約定注文)
      #
      # @param [Integer] target_order_id 注文ID
      # @return [Hash, nil, false] 注文情報
      def get_active_order(target_order_id)
        # order_id が 0 だったら注文時に全て約定済み
        return nil if target_order_id == 0

        response = get_active_orders
        return false unless response.valid?

        order = response.params['return'].find{ |order_id, order| order_id.to_i == target_order_id.to_i }

        order.nil? ? nil : order[1]
      end

      # 注文をキャンセルする
      #
      # @param [Integer] order_id 注文ID
      # @return [Arbitrager::Api::Response] APIレスポンス
      def cancel_order(order_id)
        send_private_request(:cancel_order, METHOD_POST, '/tapi', {
          method: 'cancel_order',
          nonce: nonce,
          currency_pair: PRODUCT_CODE,
          order_id: order_id,
        }.to_query)
      end

      # 総資産の一覧を取得する
      #
      # @return [Arbitrager::Api::Response] APIレスポンス
      def get_balance
        send_private_request(:get_balance, METHOD_POST, '/tapi', {
          method: 'get_info',
          nonce: nonce,
        }.to_query)
      end

      private

      # Public API用リクエスト送信
      #
      # @return [Arbitrager::Api::Response] APIレスポンス
      def send_request(method_code, method, path, query = nil, header = nil)
        response = client.send_request!(method, path, query, header)
        Arbitrager::Api::Response.new(response, Arbitrager::Api::Validator::Zaif.new(method_code))
      end

      # Private API用リクエスト送信
      #
      # @return [Arbitrager::Api::Response] APIレスポンス
      def send_private_request(method_code, method, path, query = nil)
        header = request_header(query)
        send_request(method_code, method, path, query, header)
      end

      # リクエストヘッダー作成
      def request_header(query)
        {
          'key' => Arbitrager.brokers.zaif.key,
          'sign' => signature(query),
        }
      end

      # 認証トークン作成
      def signature(query)
        secret = Arbitrager.brokers.zaif.secret

        OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA512.new, secret, query)
      end

      # nonce取得
      def nonce
        Time.now.to_i
      end
    end
  end
end
