# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Balances::Zaif do
  let(:balance) { Arbitrager::Balances::Zaif.new }
  let(:endpoint_url) { Arbitrager::Api::Zaif::ENDPOINT_URL }
  let(:json) { fixture('balancer/zaif/' + json_file) }
  let(:stub_get_balance) {
    stub_request(:post, endpoint_url + "/tapi")
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
        expect(balance.jpy).to eq(30000.0)
      end

      it "BTCの数量が取得できている" do
        expect(balance.btc).to eq(0.5)
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
      before { stub_get_balance.to_return(body: { a: 1 }.to_json, status:200 )}
      it { is_expected.to be_falsey }
    end

    context "サーバAPI実行結果が不成功の場合" do
      before { stub_get_balance.to_return(body: { success: 0 }.to_json, status:200 )}
      it { is_expected.to be_falsey }
    end
  end

  # 資産の偏りがあるかどうか
  describe "#ok?" do
    subject { balance.ok? }
    before {
      stub_get_balance.to_return(body: json, status: 200)
      balance.refresh
    }

    context "資産の偏りがない場合" do
      let(:json_file) { 'balance_ok.json' }
      it { is_expected.to be_truthy }
    end

    context "資産の偏りがある場合" do
      context "JPYの閾値がNG" do
        let(:json_file) { 'balance_ng_jpy.json' }
        it { is_expected.to be_falsey }
      end

      context "BTCの閾値がNG" do
        let(:json_file) { 'balance_ng_btc.json' }
        it { is_expected.to be_falsey }
      end
    end
  end
end
