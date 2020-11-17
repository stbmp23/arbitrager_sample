# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Api::BitBank do
  let(:client) { Arbitrager::Api::BitBank.new }
  let(:endpoint_url_public) { Arbitrager::Api::BitBank::ENDPOINT_URL_PUBLIC }
  let(:endpoint_url_private) { Arbitrager::Api::BitBank::ENDPOINT_URL_PRIVATE }
  let(:product_code) { 'btc_jpy' }
  let(:json) { fixture_api('bitbank/' + json_file).read }

  # 板情報を取得する
  describe "#order_books" do
    let(:stub_order_books) { stub_request(:get, endpoint_url_public + "/#{product_code}/depth") }
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
    let(:stub_send_order) { stub_request(:post, endpoint_url_private + "/v1/user/spot/order") }

    context "Ask注文" do
      let(:action) { 'buy' }

      context "正常完了" do
        subject { client.send_order(action, 100.0, 1.0).body }
        before { stub_send_order.and_return(body: json, status: 200) }

        it { is_expected.to eq(json) }
      end

      context "HTTP Response Status:200以外" do
        context "500 Error" do
          subject { -> { client.send_order(action, 100.0, 1.0) } }
          before { stub_send_order.and_return(body: json, status: 500) }
          it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
        end
      end
    end

    context "Bid注文" do
      let(:action) { 'sell' }

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
      stub_request(:get, endpoint_url_private + "/v1/user/spot/trade_history")
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
    let(:json_file) { 'get_order.json' }
    let(:stub_get_order) {
      stub_request(:get, endpoint_url_private + "/v1/user/spot/order?order_id=#{order_id}&pair=btc_jpy")
    }
    let(:order_id) { 123 }

    context "正常完了" do
      subject { client.get_order(order_id).body }
      before { stub_get_order.to_return(body: json, status: 200) }

      it { is_expected.to eq(json) }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.get_order(order_id) } }
        before { stub_get_order.and_return(body: '', status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end
  end

  # 注文一覧を取得する(未約定注文一覧)
  describe "#get_active_orders" do
    let(:json_file) { 'get_active_orders.json' }
    let(:stub_get_active_orders) {
      stub_request(:get, endpoint_url_private + "/v1/user/spot/active_orders?pair=btc_jpy")
    }

    context "正常完了" do
      subject { client.get_active_orders.body }
      before { stub_get_active_orders.to_return(body: json, status: 200) }

      it { is_expected.to eq(json) }
    end

    context "HTTP Response Status:200以外" do
      context "500 Error" do
        subject { -> { client.get_active_orders } }
        before { stub_get_active_orders.and_return(body: '', status: 500) }

        it { is_expected.to raise_error(Arbitrager::Error::ApiResponseError) }
      end
    end
  end

  # 注文一覧を取得する(未約定注文一覧)
  describe "#get_active_order" do
    let(:order_id) { 123 }
    let(:stub_get_active_order) {
      stub_request(:get, endpoint_url_private + "/v1/user/spot/order?order_id=#{order_id}&pair=btc_jpy")
    }

    context "未約定の注文が見つかった場合" do
      subject { client.get_active_order(order_id) }
      let(:json_file) { 'get_active_order.json' }
      before { stub_get_active_order.to_return(body: json, status: 200) }

      it { is_expected.to_not be_nil }
    end

    context "注文が約定済みの場合" do
      subject { client.get_active_order(order_id) }
      let(:json_file) { 'get_active_order_executed.json' }
      before { stub_get_active_order.to_return(body: json, status: 200) }

      it { is_expected.to be_nil }
    end

    context "指定IDの注文が見つからなかった場合" do
      subject { client.get_active_order(order_id) }
      let(:json_file) { 'get_active_order_not_found.json' }
      before { stub_get_active_order.to_return(body: json, status: 200) }

      it { is_expected.to be_falsey }
    end
  end

  # 資産一覧取得
  describe "#get_balance" do
    let(:json_file) { 'get_balance.json' }
    let(:stub_get_balance) { stub_request(:get, endpoint_url_private + "/v1/user/assets") }

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
