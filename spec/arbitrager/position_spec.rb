# frozen_string_literal: true

describe Arbitrager::Position do
  let(:position) { Arbitrager::Position.new(ask, bid) }
  let(:ask) { Arbitrager::Board::Position.new(:bitflyer, ask_price, ask_volume) }
  let(:bid) { Arbitrager::Board::Position.new(:coincheck, bid_price, bid_volume) }
  let(:ask_price) { 100.0 }
  let(:ask_volume) { 1.0 }
  let(:bid_price) { 120.0 }
  let(:bid_volume) { 1.0 }
  let(:max_size) { 10.0 }
  let(:threshold_jpy) { 1000.0 }
  let(:threshold_btc) { 10.0 }
  let(:ask_balance_jpy) { 10000.0 }
  let(:ask_balance_btc) { 100.0 }
  let(:bid_balance_jpy) { 10000.0 }
  let(:bid_balance_btc) { 100.0 }
  let(:ask_exchange_price) { 10.0 }
  let(:bid_exchange_price) { 20.0 }
  before {
    allow(Settings).to receive(:max_size).and_return(max_size)
    allow(position).to receive(:threshold_jpy).and_return(threshold_jpy)
    allow(position).to receive(:threshold_btc).and_return(threshold_btc)
    allow(position.ask_balance).to receive(:jpy).and_return(ask_balance_jpy)
    allow(position.ask_balance).to receive(:btc).and_return(ask_balance_btc)
    allow(position.bid_balance).to receive(:jpy).and_return(bid_balance_jpy)
    allow(position.bid_balance).to receive(:btc).and_return(bid_balance_btc)
    allow(position.ask).to receive(:exchange_price).and_return(ask_exchange_price)
    allow(position.bid).to receive(:exchange_price).and_return(bid_exchange_price)
  }

  # 目標利益
  describe "#target_profit" do
    context "正常" do
      subject { position.target_profit }
      it { is_expected.to eq(bid_price - ask_price) }
    end
  end

  # 目標獲得数量
  describe "#target_volume" do
    subject { position.target_volume }

    context "Ask注文の数量が最小となる(売り板の数量)" do
      let(:ask_volume) { 0.001 }
      it { is_expected.to eq(ask_volume) }
    end

    context "Bid注文の数量が最小となる(買い板の数量)" do
      let(:bid_volume) { 0.002 }
      it { is_expected.to eq(bid_volume) }
    end

    context "Settings.max_sizeの値が最小となる" do
      let(:max_size) { 0.003 }
      it { is_expected.to eq(max_size) }
    end
  end

  # 目標利益(JPY)
  describe "#target_profit_price" do
  end

  # 目標利益率(％)
  describe "#target_profit_percent" do
    subject { position.target_profit_percent }

    before {
      allow(position).to receive(:target_profit).and_return(20.0)
      allow(position).to receive(:target_volume).and_return(1.0)
    }

    context "正常" do
      it { is_expected.to eq((20.0 / (110.0 * 1.0)) * 100.0) }
    end
  end

  # 取引可能かどうか(Ask:買い)
  describe "#can_ask?" do
    subject { position.can_ask? }

    context "資産(JPY)で購入が可能" do
      it { is_expected.to be_truthy }
    end

    context "資産(JPY)が閾値よりも低い場合は購入できない" do
      let(:ask_balance_jpy) { 10.0 }
      it { is_expected.to be_falsey }
    end

    context "資産(JPY) < 購入金額 の場合は購入できない" do
      let(:ask_exchange_price) { 1_000_000.0 }
      it { is_expected.to be_falsey }
    end
  end

  # 取引可能かどうか(Bid:売り)
  describe "#can_bid?" do
    subject { position.can_bid? }

    context "資産(BTC)で売却が可能" do
      it { is_expected.to be_truthy }
    end

    context "資産(BTC)が閾値よりも低い場合は購入できない" do
      let(:bid_balance_btc) { 0.1 }
      it { is_expected.to be_falsey }
    end

    context "資産(BTC) < 売却数量 の場合は売却できない" do
      before { allow(position).to receive(:target_volume).and_return(1_000_000.0) }
      it { is_expected.to be_falsey }
    end
  end

  # 取引可能かどうか
  describe "#can_exchange?" do
    subject { position.can_exchange? }

    before {
      allow(Settings).to receive(:min_target_profit).and_return(0)
      allow(Settings).to receive(:min_target_profit_percent).and_return(0)
      allow(Settings).to receive(:min_size).and_return(0.0)
      allow(Settings).to receive(:max_size).and_return(1000.0)
    }

    context "正常" do
      it { is_expected.to be_truthy }
    end
  end
end
