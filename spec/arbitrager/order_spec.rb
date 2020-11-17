# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Order do
  let(:order) { Arbitrager::Order.new(broker_code, order_type, price, volume) }
  let(:broker_code){ :bitflyer}
  let(:order_type){ :ask }
  let(:price){ 1_612_150.0 }
  let(:volume){ 0.01 }

  # 反対注文時の価格を計算する
  describe "#reverse_price" do
    subject { order.reverse_price }

    context "Ask(購入注文)の反対売買時(Bid)は元の価格より高くする" do
      let(:order_type){ :ask }
      it { is_expected.to eq(1612310.0) }

      it "5で割り切れる" do
        expect(order.reverse_price % 5).to eq(0)
      end
    end

    context "Bid(売却注文)の反対売買時(Ask)は元の価格より低くする" do
      let(:order_type){ :bid }
      it { is_expected.to eq(1611990.0) }

      it "5で割り切れる" do
        expect(order.reverse_price % 5).to eq(0)
      end
    end
  end
end
