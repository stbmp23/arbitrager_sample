# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Exchanger do
  let(:exchanger) { Arbitrager::Exchanger.new(bid_order, ask_order) }
  let(:ask_order) { Arbitrager::Orders::BitFlyer.create_ask(1_000_000, 1.0) }
  let(:bid_order) { Arbitrager::Orders::Zaif.create_bid(1_200_000, 1.0) }
  let(:ask_position) { Arbitrager::Board::Position.new(:bitflyer, 1_000_000.0, 1.0) }
  let(:bid_position) { Arbitrager::Board::Position.new(:zaif, 1_200_000.0, 1.0) }
  let(:position) { Arbitrager::Position.new(ask_position, bid_position) }

  before {
    allow(Arbitrager.analyzer).to receive(:target_position).and_return(position)
    allow(Arbitrager.analyzer.target_position).to receive(:target_profit_price).and_return(1.0)
  }

  # 注文を実行優先順に並び替える
  describe "#sorted_orders" do
    context "設定した優先順に並び替えができている" do
      subject { exchanger.sorted_orders }
      before {
        allow(ask_order.broker).to receive(:priority).and_return(2)
        allow(bid_order.broker).to receive(:priority).and_return(1)
      }

      it { is_expected.to eq([bid_order, ask_order]) }
    end
  end

  describe "#start!" do
    context "1つめの注文が失敗したら取引きを中断する" do
      subject { exchanger.start! }
      before {
        allow(exchanger.first_order).to receive(:send_request!).and_return(false)
      }

      it { is_expected.to be_falsey }
    end

    context "1つめの注文だけ成功した場合" do
      before {
        allow(exchanger.first_order).to receive(:send_request!).and_return(true)
        allow(exchanger.second_order).to receive(:send_request!).and_return(false)
        exchanger.first_order.model.order_acceptance_id = 123
      }

      context "1つめの注文が約定前" do
        subject { exchanger.model.result }
        before {
          response = double('response')
          allow(exchanger.first_order).to receive(:execution?).and_return(false)
          allow(exchanger.first_order.client).to receive(:cancel_order).and_return(response)
          allow(response).to receive(:valid?).and_return(true)
          allow(response).to receive(:body).and_return('')
          allow(response).to receive(:params).and_return({ 'success' => 1 })
          exchanger.start!
        }

        it { is_expected.to be_falsey }

        it "DBに履歴が保存されている" do
          order = Arbitrager::Models::Order.where(order_acceptance_id: exchanger.first_order.model.order_acceptance_id).first
          expect(order.cancel_flg).to be_truthy
        end
      end

      context "1つめの注文が約定されている" do
        subject { exchanger.model.result }
        before {
          reverse_order = "Arbitrager::Orders::#{exchanger.first_order.broker.name.classify}".constantize.create_ask(1_000_000, 1.0)
          allow(exchanger.first_order).to receive(:execution?).and_return(true)
          allow(exchanger.first_order.client).to receive(:cancel_order).and_return(true)
          allow(exchanger.first_order).to receive(:reverse_order).and_return(reverse_order)
          allow(exchanger.first_order.reverse_order).to receive(:send_request!).and_return(true)
          exchanger.start!
        }

        it { is_expected.to be_falsey }

        it "1つめの注文履歴がDBにある" do
          order = Arbitrager::Models::Order.where(broker_id: exchanger.first_order.broker.id).first
          expect(order).to_not be_nil
        end

        it "反対売買の注文履歴がDBにある" do
          reverse_order = Arbitrager::Models::Order.where({
            broker_id: exchanger.first_order.broker.id,
            reverse_order_flg: true,
          }).first
          expect(reverse_order).to_not be_nil
        end
      end
    end

    context "両方の注文が成功した場合" do
      subject { exchanger.model.result }

      before {
        allow(exchanger.first_order).to receive(:send_request!).and_return(true)
        allow(exchanger.second_order).to receive(:send_request!).and_return(true)
        exchanger.first_order.model.order_acceptance_id = 123
        exchanger.second_order.model.order_acceptance_id = 123
      }

      context "しばらく経過しても片方しか約定しなかった場合" do
        context "1つめの注文が約定しなかった場合" do
          before {
            allow(exchanger.first_order).to receive(:execution?).and_return(false)
            allow(exchanger.second_order).to receive(:execution?).and_return(true)
          }

          subject { exchanger.model.result }
          before {
            # 1つめの注文をキャンセル注文できるようにする
            response = double('response')
            allow(exchanger.first_order.client).to receive(:cancel_order).and_return(response)
            allow(response).to receive(:valid?).and_return(true)
            allow(response).to receive(:body).and_return('')
            allow(response).to receive(:params).and_return({ 'success' => 1 })
            # 2つめの注文を反対売買できるようにする
            reverse_order = "Arbitrager::Orders::#{exchanger.second_order.broker.name.classify}".constantize.create_ask(1_000_000, 1.0)
            allow(exchanger.second_order.client).to receive(:cancel_order).and_return(true)
            allow(exchanger.second_order).to receive(:reverse_order).and_return(reverse_order)
            allow(exchanger.second_order.reverse_order).to receive(:send_request!).and_return(true)

            exchanger.start!
          }

          it { is_expected.to be_falsey }

          it "1つめの注文のキャンセル注文がDBに存在する" do
            order = Arbitrager::Models::Order.where(
              broker_id: exchanger.first_order.broker.id,
              cancel_flg: true
            ).first
            expect(order).to_not be_nil
          end

          it "2つめの注文がDBに存在する" do
            order = Arbitrager::Models::Order.where(
              broker_id: exchanger.second_order.broker.id,
              reverse_order_flg: false
            ).first
            expect(order).to_not be_nil
          end

          it "２つめの注文の反対売買注文がDBに存在する" do
            order = Arbitrager::Models::Order.where(
              broker_id: exchanger.second_order.broker.id,
              reverse_order_flg: true
            ).first
            expect(order).to_not be_nil
          end
        end

        context "2つめの注文が約定しなかった場合" do
          before {
            allow(exchanger.first_order).to receive(:execution?).and_return(true)
            allow(exchanger.second_order).to receive(:execution?).and_return(false)
          }

          subject { exchanger.model.result }
          before {
            # 1つめの注文を反対売買できるようにする
            reverse_order = "Arbitrager::Orders::#{exchanger.first_order.broker.name.classify}".constantize.create_ask(1_000_000, 1.0)
            allow(exchanger.first_order.client).to receive(:cancel_order).and_return(true)
            allow(exchanger.first_order).to receive(:reverse_order).and_return(reverse_order)
            allow(exchanger.first_order.reverse_order).to receive(:send_request!).and_return(true)
            # 2つめの注文をキャンセル注文できるようにする
            response = double('response')
            allow(exchanger.second_order.client).to receive(:cancel_order).and_return(response)
            allow(response).to receive(:valid?).and_return(true)
            allow(response).to receive(:body).and_return('')
            allow(response).to receive(:params).and_return({})

            exchanger.start!
          }

          it { is_expected.to be_falsey }

          it "2つめの注文のキャンセル注文がDBに存在する" do
            order = Arbitrager::Models::Order.where(
              broker_id: exchanger.second_order.broker.id,
              cancel_flg: true
            ).first
            expect(order).to_not be_nil
          end

          it "1つめの注文がDBに存在する" do
            order = Arbitrager::Models::Order.where(
              broker_id: exchanger.first_order.broker.id,
              reverse_order_flg: false
            ).first
            expect(order).to_not be_nil
          end

          it "１つめの注文の反対売買注文がDBに存在する" do
            order = Arbitrager::Models::Order.where(
              broker_id: exchanger.first_order.broker.id,
              reverse_order_flg: true
            ).first
            expect(order).to_not be_nil
          end
        end
      end

      context "両方の注文が約定した場合" do
        before {
          allow(exchanger.first_order).to receive(:execution?).and_return(true)
          allow(exchanger.second_order).to receive(:execution?).and_return(true)
          exchanger.start!
        }

        it { is_expected.to be_truthy }

        it "取引情報がDBに保存されている" do
          exchange = Arbitrager::Models::Exchange.where(result: true).first
          expect(exchange).to_not be_nil
        end

        it "1つめの注文履歴がDBに保存されている" do
          order = Arbitrager::Models::Order.where(
            broker_id: exchanger.first_order.broker.id,
          ).first
          expect(order).to_not be_nil
        end

        it "2つめの注文履歴がDBに保存されている" do
          order = Arbitrager::Models::Order.where(
            broker_id: exchanger.second_order.broker.id,
          ).first
          expect(order).to_not be_nil
        end
      end
    end
  end

  # DBへ取引内容を保存する
  describe "#save_trades" do
    context "注文が約定している場合" do
      before {
        allow(ask_order.broker).to receive(:priority).and_return(1)
        allow(bid_order.broker).to receive(:priority).and_return(2)
      }

      before {
        allow(exchanger.first_order.model).to receive(:result).and_return(true)
        allow(exchanger.first_order).to receive(:update_execution).and_return(true)
        allow(exchanger.second_order.model).to receive(:result).and_return(true)
        allow(exchanger.second_order).to receive(:update_execution).and_return(true)

        exchanger.first_order.model.price = 20.0
        exchanger.second_order.model.price = 30.0

        exchanger.send(:save_trades)
      }

      it "利益がDBに保存されている" do
        exchange = Arbitrager::Models::Exchange.first
        expect(exchange.benefit).to eq(10.0)
      end
    end
  end
end
