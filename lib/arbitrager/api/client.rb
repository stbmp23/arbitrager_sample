# frozen_string_literal: true

require 'arbitrager/api/concern'

module Arbitrager
  module Api
    class Client
      include Arbitrager::Api::Concern

      attr_reader :client

      def initialize(endpoint_url)
        @client = http_client(endpoint_url)
      end

      # APIにリクエストを送信して結果を返す
      def send_request!(method, path, query = nil, header = nil)
        mes = get_method(method)

        response = client.send(mes, path, query) do |req|
          req.headers = header if header
          # req.options.timeout = 5 # open/read timeout in seconds
          req.options.open_timeout = 2 # connection open timeout in seconds
        end

        if response.status != 200
          raise Arbitrager::Error::ApiResponseError.new(path, query, header, response)
        end

        response
      rescue => e
        Arbitrager.logger.fatal(e)
        raise e
      end

      # メソッドタイプ取得
      def get_method(method)
        case method
        when METHOD_GET
          :get
        when METHOD_POST
          :post
        when METHOD_DELETE
          :delete
        when METHOD_PUT
          :put
        else
          raise "Undefind method: #{method}"
        end
      end

      private

      def http_client(endpoint_url)
        Faraday.new(url: endpoint_url) do |faraday|
          faraday.request  :url_encoded
          # faraday.adapter  Faraday.default_adapter
          faraday.adapter :httpclient do |client|
            # client.debug_dev = STDOUT
            # client.connect_timeout = 2
            # client.send_timeout = 1
            # client.receive_timeout = 2
            client.cookie_manager = nil
          end
        end
      end
    end
  end
end
