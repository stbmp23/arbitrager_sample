# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Balances::BitBank do
  let(:balance) { Arbitrager::Balances::BitBank.new }
  let(:endpoint_url) { Arbitrager::Api::BitBank::ENDPOINT_URL_PRIVATE }
  let(:json) { fixture('balancer/bitbank/' + json_file) }
  let(:stub_get_balance) {
    stub_request(:get, endpoint_url + "/v1/user/assets")
  }

  # 資産状況の更新を行う
  describe "#refresh" do
    let(:json_file) { 'balance_ok.json' }
    subject { balance.refresh }

    context "資産状況の更新に成功した場合" do
      before {
        stub_get_balance.to_return(body: json, status: 200)
        balance.refresh
      }

      it { is_expected.to be_truthy }

      it "JPYの数量が取得できている" do
        expect(balance.jpy).to eq(30.0)
      end

      it "BTCの数量が取得できている" do
        expect(balance.btc).to eq(10.0)
      end
    end

    context "リクエストタイムアウト" do
      before { stub_get_balance.to_timeout }
      it { is_expected.to be_falsey }
    end

    context "HTTP Status200以外" do
      before { stub_get_balance.to_return(body: '', status: 500) }
      it { is_expected.to be_falsey }
    end

    context "予期しないレスポンスBodyが返ってきた場合" do
      before { stub_get_balance.to_return(body: { a: 1 }.to_json, status: 200) }
      it { is_expected.to be_falsey }
    end
  end
end
