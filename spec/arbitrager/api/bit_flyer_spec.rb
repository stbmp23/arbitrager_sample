# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Api::BitFlyer do
  let(:client) { Arbitrager::Api::BitFlyer.new }
  let(:endpoint_url) { Arbitrager::Api::BitFlyer::ENDPOINT_URL }
  let(:json) { fixture_api('bitflyer/' + json_file).read }

  # 板情報を取得する
  describe "#order_books" do
    let(:stub_order_books) { stub_request(:get, endpoint_url + "/v1/getboard") }
    let(:json_file) { 'order_books.json' }

    context "正常完了" do
      subject { client.order_books.body }
      before { stub_order_books.to_return(:body => json, :status => 200) }

      it { is_expected.to eq(json) }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.order_books } }
        before { stub_order_books.and_return(body: json, status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end
  end

  # 注文を作成する
  describe "#send_order" do
    let(:json_file) { 'send_order.json' }
    let(:stub_send_order) { stub_request(:post, endpoint_url + "/v1/me/sendchildorder") }

    context "Ask注文" do
      let(:action) { 'BUY' }

      context "正常完了" do
        subject { client.send_order(action, 100.0, 1.0).body }
        before { stub_send_order.and_return(body: json, status: 200) }

        it { is_expected.to eq(json) }
      end

      context "HTTP Response Status:200以外" do
        context "500 Error" do
          subject { -> { client.send_order(action, 100.0, 1.0) } }
          before { stub_send_order.and_return(body: '', status: 500) }

          it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
        end
      end
    end

    context "Bid注文" do
      let(:action) { 'SELL' }

      context "正常完了" do
        subject { client.send_order(action, 100.0, 1.0).body }
        before { stub_send_order.and_return(body: json, status: 200) }

        it { is_expected.to eq(json) }
      end
    end
  end

  # 注文一覧を取得する
  describe "#get_orders" do
    let(:json_file) { 'get_orders.json' }
    let(:stub_get_orders) {
      stub_request(:get, endpoint_url + "/v1/me/getchildorders?product_code=BTC_JPY")
    }

    context "正常完了" do
      subject { client.get_orders.body }
      before { stub_get_orders.to_return(body: json, status: 200) }

      it { is_expected.to eq(json) }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.get_orders } }
        before { stub_get_orders.and_return(body: '', status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end
  end

  # 注文を1件取得する
  describe "#get_order" do
    let(:json_file) { 'get_orders.json' }
    let(:stub_get_order) {
      stub_request(:get, endpoint_url + "/v1/me/getchildorders?product_code=BTC_JPY&order_acceptance_id=#{order_id}")
    }
    let(:order_id) { 'JRF20150707-084552-031927' }

    context "正常完了" do
      subject { client.get_order(order_id) }
      before { stub_get_order.to_return(body: json, status: 200) }

      it { is_expected.to_not be_nil }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.get_order(order_id) } }
        before { stub_get_order.and_return(body: '', status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end

    context "レスポンスBodyがおかしい場合" do
      subject { client.get_order(order_id) }
      before { stub_get_order.and_return(body: { a: 1 }.to_json, status: 200) }

      it { is_expected.to be_falsey }
    end
  end

  # 注文キャンセル
  describe "#cancel_order" do
    let(:stub_cancel_order) {
      stub_request(:post, endpoint_url + "/v1/me/cancelchildorder")
        .with(body: { product_code: 'BTC_JPY', child_order_acceptance_id: 123 }.to_json)
    }

    context "正常完了" do
      subject { client.cancel_order(123) }
      before { stub_cancel_order.to_return(body: '', status: 200) }

      it { is_expected.to be_truthy }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.cancel_order(123) } }
        before { stub_cancel_order.and_return(body: '', status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end
  end

  # 資産一覧取得
  describe "#get_balance" do
    let(:json_file) { 'get_balance.json' }
    let(:stub_get_balance) { stub_request(:get, endpoint_url + "/v1/me/getbalance") }

    context "正常完了" do
      subject { client.get_balance.body }
      before { stub_get_balance.to_return(body: json, status: 200) }

      it { is_expected.to eq(json) }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.get_balance } }
        before { stub_get_balance.and_return(body: '', status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end
  end
end
