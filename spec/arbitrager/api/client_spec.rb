# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Api::Client do
  let(:client) { Arbitrager::Api::Client.new(endpoint_url) }
  let(:endpoint_url) { 'http://localhost' }
  let(:stub_send_request) { stub_request(action, endpoint_url) }

  # APIにリクエストを送信して結果を返す
  describe "#send_request!" do
    %w(GET POST PUT DELETE).each do |method|
      context method do
        # let(:method) { 'GET' }
        let(:action) { method.downcase.to_sym }

        context "正常完了" do
          let(:body) { { a: 1 }.to_json }
          before { stub_send_request.to_return(body: body, status: 200) }
          subject { client.send_request!(method, '/').body }

          it { is_expected.to eq(body) }
        end

        context "レスポンスBodyが空" do
          before { stub_send_request.to_return(body: '', status: 200) }
          subject { client.send_request!(method, '/').body }

          it { is_expected.to be_truthy }
        end

        context "HTTP Statusが200以外" do
          before { stub_send_request.to_return(body: '', status: 404) }
          subject { -> { client.send_request!(method, '/') } }

          it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
        end

        context "Network connection error" do
          before { stub_send_request.to_raise(SocketError) }
          subject { -> { client.send_request!(method, '/') } }

          it { is_expected.to raise_error(Faraday::ConnectionFailed) }
        end

        context "Connection Timeout" do
          before { stub_send_request.to_timeout }
          subject { -> { client.send_request!(method, '/') } }

          it { is_expected.to raise_error(Faraday::Error::TimeoutError) }
        end
      end
    end
  end
end
