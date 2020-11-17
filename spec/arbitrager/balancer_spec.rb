# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Balancer do
  let(:balancer) { Arbitrager::Balancer.new }

  # 資産状況の更新を行う
  describe "#refresh" do
    subject { balancer.refresh }

    context "資産状況の更新が正常に完了した場合" do
      before {
        balancer.balances.each do |balance|
          allow(balance).to receive(:refresh).and_return(true)
        end
      }

      it { is_expected.to be_truthy }
    end

    context "資産状況の更新に失敗した場合" do
      before {
        balancer.balances.each do |balance|
          allow(balance).to receive(:refresh).and_return(false)
        end
      }

      it { is_expected.to be_falsey }
    end
  end
end
