# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Board::Analyzer do
  let(:analyzer) { Arbitrager::Board::Analyzer.new }

  describe "#refresh" do
    subject { analyzer.refresh }

    context "板情報の更新に成功" do
      before {
        analyzer.boards.each{ |board|
          allow(board).to receive(:refresh).and_return(true)
        }
      }

      it { is_expected.to be_truthy }
    end

    context "板情報の更新に失敗" do
      before {
        analyzer.boards.each{ |board|
          allow(board).to receive(:refresh).and_return(false)
        }
      }

      it { is_expected.to be_falsey }
    end
  end

  describe "#target_position" do
    before {

    }
  end

  describe "#best_bid" do
  end

  describe "#best_ask" do
  end

  describe "#target_net_exposure" do
  end

  describe "#can_exchange?" do
  end
end
