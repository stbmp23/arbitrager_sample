# frozen_string_literal: true

describe Arbitrager::Board::Position do
  let(:position) { Arbitrager::Board::Position.new(broker_code, price, volume) }
  let(:broker_code) { :bitflyer }
  let(:price) { 100.0 }
  let(:volume) { 1.2 }
  let(:target_volume) { 2.0 }
  let(:action) { :ask }
  before {
    position.target_volume = target_volume
    position.action = action
  }

  # 取引価格(手数料抜き)
  describe "#exchange_base_price" do
    subject { position.exchange_base_price }

    context "正常" do
      it { is_expected.to eq(price * target_volume) }
    end
  end

  # 取引価格(手数料込み)
  describe "#exchange_price" do
    subject { position.exchange_price }

    let(:exchange_base_price) { 100.0 }
    let(:commission) { 1.0 }
    before {
      allow(position).to receive(:exchange_base_price).and_return(exchange_base_price)
      allow(position).to receive(:commission).and_return(commission)
    }

    context "Askの場合" do
      it { is_expected.to eq(exchange_base_price + commission) }
    end

    context "Bidの場合" do
      let(:action) { :bid }
      it { is_expected.to eq(exchange_base_price - commission) }
    end

    context "actionが不定義のもの" do
      subject { -> { position.exchange_price } }
      let(:action) { :undefined }
      it { is_expected.to raise_error(StandardError) }
    end
  end

  # 手数料
  describe "#commission" do
    subject { position.commission }

    let(:exchange_base_price) { 100.0 }
    let(:commission_percent) { 1.0 }
    before {
      allow(position).to receive(:exchange_base_price).and_return(exchange_base_price)
      allow(position.broker).to receive(:commission_percent).and_return(commission_percent)
    }

    context "手数料1%" do
      it { is_expected.to eq(1.0) }
    end

    context "手数料0%" do
      let(:commission_percent) { 0.0 }
      it { is_expected.to eq(0.0) }
    end
  end
end
