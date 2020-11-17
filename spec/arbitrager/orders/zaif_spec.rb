# frozen_string_literal: true

require 'spec_helper'

describe Arbitrager::Orders::Zaif do
  let(:order_ask) { Arbitrager::Orders::Zaif.create_ask(2_000_000.0, 0.001) }
  let(:order_bid) { Arbitrager::Orders::Zaif.create_bid(2_000_000.0, 0.001) }
  let(:endpoint_url) { Arbitrager::Api::Zaif::ENDPOINT_URL }
  let(:stub_send_order) { stub_request(:post, endpoint_url + "/tapi") }
  let(:json) { fixture_api('zaif/' + json_file).read }
  let(:attributes) {
    model.attributes.slice(
      'broker_id',
      'action_id',
      'target_price',
      'target_volume',
      'order_acceptance_id',
      'result',
      'response',
      'execution_flg',
      'reverse_order_flg',
      'cancel_flg'
    )
  }

  # APIに注文リクエストを送信する
  describe "#send_request!" do
    context "Ask注文の場合" do
      subject { order_ask.send_request! }

      context "正常完了" do
        let(:json_file) { 'send_order.json' }
        let(:model) { order_ask.model }
        before { stub_send_order.to_return(body: json, status: 200) }

        it { is_expected.to be_truthy }

        it "注文情報がモデルへ保存される" do
          order_ask.send_request!

          expect(attributes).to eq({
            'broker_id' => Settings.broker.zaif.id,
            'action_id' => Settings.actions.ask.id,
            'target_price' => 2_000_000.0,
            'target_volume' => 0.001,
            'order_acceptance_id' => '298273768',
            'result' => true,
            'response' => json,
            'reverse_order_flg' => false,
            'execution_flg' => false,
            'cancel_flg' => false,
          })
        end
      end

      context "リクエストタイムアウト" do
        before { stub_send_order.to_timeout }
        it { is_expected.to be_falsey }
      end

      context "HTTP Status 200以外" do
        before { stub_send_order.to_return(body: '', status: 500) }
        it { is_expected.to be_falsey }
      end

      context "予期しないレスポンスBodyが返ってきた場合" do
        before { stub_send_order.to_return(body: { a: 1 }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end

      context "APIの実行結果が失敗の場合" do
        before { stub_send_order.to_return(body: { "success" => 0, "return" => 'abc' }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end
    end

    context "Bid注文の場合" do
      subject { order_bid.send_request! }

      context "正常完了" do
        let(:json_file) { 'send_order.json' }
        let(:model) { order_bid.model }
        before { stub_send_order.to_return(body: json, status: 200) }

        it { is_expected.to be_truthy }

        it "注文情報がモデルへ保存される" do
          order_bid.send_request!

          expect(attributes).to eq({
            'broker_id' => Settings.broker.zaif.id,
            'action_id' => Settings.actions.bid.id,
            'target_price' => 2_000_000.0,
            'target_volume' => 0.001,
            'order_acceptance_id' => '298273768',
            'result' => true,
            'response' => json,
            'reverse_order_flg' => false,
            'execution_flg' => false,
            'cancel_flg' => false,
          })
        end
      end

      context "リクエストタイムアウト" do
        before { stub_send_order.to_timeout }
        it { is_expected.to be_falsey }
      end

      context "HTTP Status 200以外" do
        before { stub_send_order.to_return(body: '', status: 500) }
        it { is_expected.to be_falsey }
      end

      context "予期しないレスポンスBodyが返ってきた場合" do
        before { stub_send_order.to_return(body: { a: 1 }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end

      context "APIの実行結果が失敗の場合" do
        before { stub_send_order.to_return(body: { "success" => 0, "return" => 'abc' }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end
    end
  end

  # 確定済みの注文に対して反対注文を出す
  describe "#send_reverse_request!" do
    context "Ask注文の場合" do
      subject { order_ask.send_reverse_request! }

      context "正常完了" do
        let(:json_file) { 'send_order.json' }
        let(:model) { order_ask.reverse_order.model }
        before { stub_send_order.to_return(body: json, status: 200) }

        it { is_expected.to be_truthy }

        it "注文情報がモデルへ保存される" do
          order_ask.send_reverse_request!

          expect(attributes).to eq({
            'broker_id' => Settings.broker.zaif.id,
            'action_id' => Settings.actions.bid.id,
            'target_price' => 2_000_200.0,
            'target_volume' => 0.001,
            'order_acceptance_id' => '298273768',
            'result' => true,
            'response' => json,
            'reverse_order_flg' => true,
            'execution_flg' => false,
            'cancel_flg' => false,
          })
        end
      end

      context "リクエストタイムアウト" do
        before { stub_send_order.to_timeout }
        it { is_expected.to be_falsey }
      end

      context "HTTP Status 200以外" do
        before { stub_send_order.to_return(body: '', status: 500) }
        it { is_expected.to be_falsey }
      end

      context "予期しないレスポンスBodyが返ってきた場合" do
        before { stub_send_order.to_return(body: { a: 1 }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end

      context "APIの実行結果が失敗の場合" do
        before { stub_send_order.to_return(body: { "success" => 0, "return" => 'abc' }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end
    end

    context "Bid注文の場合" do
      subject { order_bid.send_reverse_request! }

      context "正常完了" do
        let(:json_file) { 'send_order.json' }
        let(:model) { order_bid.reverse_order.model }
        before { stub_send_order.to_return(body: json, status: 200) }

        it { is_expected.to be_truthy }

        it "注文情報がモデルへ保存される" do
          order_bid.send_reverse_request!

          expect(attributes).to eq({
            'broker_id' => Settings.broker.zaif.id,
            'action_id' => Settings.actions.ask.id,
            'target_price' => 1_999_800.0,
            'target_volume' => 0.001,
            'order_acceptance_id' => '298273768',
            'result' => true,
            'response' => json,
            'reverse_order_flg' => true,
            'execution_flg' => false,
            'cancel_flg' => false,
          })
        end
      end

      context "リクエストタイムアウト" do
        before { stub_send_order.to_timeout }
        it { is_expected.to be_falsey }
      end

      context "HTTP Status 200以外" do
        before { stub_send_order.to_return(body: '', status: 500) }
        it { is_expected.to be_falsey }
      end

      context "予期しないレスポンスBodyが返ってきた場合" do
        before { stub_send_order.to_return(body: { a: 1 }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end

      context "APIの実行結果が失敗の場合" do
        before { stub_send_order.to_return(body: { "success" => 0, "return" => 'abc' }.to_json, status: 200) }
        it { is_expected.to be_falsey }
      end
    end
  end

  # 注文が約定したかどうか
  describe "#execution?" do
    subject { order_ask.execution? }
    let(:stub_get_order_request) { stub_request(:post, endpoint_url + "/tapi") }
    before { order_ask.model.order_acceptance_id = 184 }

    context "約定済み" do
      let(:json_file) { 'order_execution.json' }
      before {
        stub_get_order_request.to_return(body: json, status: 200)
      }

      it { is_expected.to be_truthy }

      it "注文モデルデータが約定済みになる" do
        order_ask.execution?
        expect(order_ask.model.execution_flg).to be_truthy
      end
    end

    context "未約定" do
      let(:json_file) { 'order_execution_false.json' }
      before {
        stub_get_order_request.to_return(body: json, status: 200)
      }

      it { is_expected.to be_falsey }

      it "注文モデルデータが未約定になっている" do
        order_ask.execution?
        expect(order_ask.model.execution_flg).to be_falsey
      end
    end

    context "オーダーIDが無いのに実行した場合" do
      subject { -> { order_ask.execution? } }
      before { order_ask.model.order_acceptance_id = nil }

      it { is_expected.to raise_error(StandardError) }
    end

    context "HTTP Status 200以外" do
      before {
        order_ask.model.order_acceptance_id = 123
        stub_get_order_request.to_return(body: '', status: 500)
      }
      it { is_expected.to be_falsey }
    end

    context "予期しないレスポンスBodyが返ってきた場合" do
      before {
        order_ask.model.order_acceptance_id = 123
        stub_get_order_request.to_return(body: { a: 1 }.to_json, status: 200)
      }
      it { is_expected.to be_falsey }
    end

    context "APIの実行結果が失敗の場合" do
      before {
        order_ask.model.order_acceptance_id = 123
        stub_get_order_request.to_return(body: { success: 0, return: 'abc' }.to_json, status: 200)
      }
      it { is_expected.to be_falsey }
    end
  end

  # キャンセル注文を出す
  describe "#cancel_request!" do
    let(:stub_cancel_request) {
      stub_request(:post, endpoint_url + "/tapi")
    }

    context "正常完了" do
      subject { order_ask.cancel_request! }
      let(:json_file) { 'cancel_order.json' }
      let(:order_acceptance_id) { '12345' }
      before {
        order_ask.model.order_acceptance_id = order_acceptance_id
        stub_cancel_request.to_return(:body => json, :status => 200)
      }

      it { is_expected.to be_truthy }

      it "注文モデルデータがキャンセル済みになっている" do
        order_ask.cancel_request!
        expect(order_ask.model.cancel_flg).to be_truthy
      end
    end

    context "オーダーIDが無いのに実行した場合" do
      subject { -> { order_ask.cancel_request! } }
      before { order_ask.model.order_acceptance_id = nil }

      it { is_expected.to raise_error(StandardError) }
    end

    context "HTTP Status 200以外" do
      subject { order_ask.cancel_request! }
      before {
        order_ask.model.order_acceptance_id = '123'
        stub_cancel_request.to_return(body: '', status: 500)
      }
      it { is_expected.to be_falsey }
    end

    context "予期しないレスポンスBodyが返ってきた場合" do
      subject { order_ask.cancel_request! }
      before {
        order_ask.model.order_acceptance_id = '123'
        stub_cancel_request.to_return(body: { a: 1 }.to_json, status: 200)
      }
      it { is_expected.to be_falsey }
    end

    context "APIの実行結果が失敗の場合" do
      subject { order_ask.cancel_request! }
      before {
        order_ask.model.order_acceptance_id = '123'
        stub_cancel_request.to_return(body: { "success" => 0, "return" => 'abc' }.to_json, status: 200)
      }
      it { is_expected.to be_falsey }
    end

    context "指定した注文IDの注文が見つからなかった場合" do
      subject { order_ask.cancel_request! }
      let(:json_file) { 'cancel_order_not_found.json' }
      let(:order_acceptance_id) { '12345' }
      before {
        order_ask.model.order_acceptance_id = order_acceptance_id
        stub_cancel_request.to_return(:body => json, :status => 200)
      }

      it { is_expected.to be_truthy }
    end
  end

  # 注文を元に戻す(キャンセルして反対売買する)
  describe "#rollback!" do
    subject { order_ask.rollback! }
    let(:stub_execution) { allow(order_ask).to receive(:execution?).and_return(result) }
    before {
      order_ask.model.order_acceptance_id = '123'
      allow(order_ask).to receive(:cancel_request!).and_return('cancel_request!')
      allow(order_ask).to receive(:send_reverse_request!).and_return('send_reverse_request!')
      stub_execution
    }

    context "約定済み" do
      let(:result) { true }

      it "反対売買が実行される" do
        is_expected.to eq('send_reverse_request!')
      end
    end

    context "未約定" do
      let(:result) { false }

      it "キャンセル処理が実行される" do
        is_expected.to eq('cancel_request!')
      end
    end
  end

  # 約定後の注文情報取得
  describe "#update_execution" do
    subject { order_bid.update_execution }
    let(:stub_get_orders) {
      stub_request(:post, endpoint_url + "/tapi")
    }

    context "約定済みの注文が取得できた場合" do
      let(:order_acceptance_id) { '123' }
      let(:json_file) { 'get_orders.json' }
      before {
        Timecop.freeze(Time.parse('2017-01-01 00:00:00'))
        order_ask.model.order_acceptance_id = order_acceptance_id
        stub_get_orders.to_return(body: json, status: 200)
      }

      it { is_expected.to be_truthy }

      it "モデルのデータが更新されている" do
        order_ask.update_execution
        params = order_ask.model.attributes.slice('price', 'volume', 'fee')
        expect(params).to eq({
          'price' => 2_000_000.0,
          'volume' => 0.04,
          'fee' => 0.0,
        })
      end
    end

    context "約定済みの注文が取得できなかった場合" do
      let(:order_acceptance_id) { '123' }
      let(:json) { { "success" => 1, "return" => {} }.to_json }
      before {
        order_bid.model.order_acceptance_id = order_acceptance_id
        stub_get_orders.to_return(body: json, status: 200)
      }

      it { is_expected.to be_truthy }

      it "モデルのデータが更新されている" do
        order_ask.update_execution
        params = order_ask.model.attributes.slice('price', 'volume', 'fee')
        expect(params).to eq({
          'price' => 0.0,
          'volume' => 0.0,
          'fee' => 0.0,
        })
      end
    end

    context "APIの実行結果が失敗の場合" do
      let(:order_acceptance_id) { '123' }
      let(:json) { { "success" => 0, "return" => 'abc' }.to_json }
      before {
        order_ask.model.order_acceptance_id = order_acceptance_id
        stub_get_orders.to_return(body: json, status: 200)
      }

      it { is_expected.to be_falsey }
    end

    context "HTTP Status 200以外" do
      let(:order_acceptance_id) { '123' }
      before {
        order_ask.model.order_acceptance_id = order_acceptance_id
        stub_get_orders.to_return(body: '', status: 500)
      }
      it { is_expected.to be_falsey }
    end

    context "予期しないレスポンスBodyが返ってきた場合" do
      let(:order_acceptance_id) { '123' }
      before {
        order_ask.model.order_acceptance_id = order_acceptance_id
        stub_get_orders.to_return(body: { a: 1 }.to_json, status: 200)
      }
      it { is_expected.to be_falsey }
    end
  end

  # 約定後の注文情報取得(実行完了まで待つ)
  describe "#update_execution!" do
    subject { order_ask.update_execution! }

    context "正常完了" do
      before {
        allow(order_ask).to receive(:update_execution).and_return(true)
      }

      it { is_expected.to be_truthy }
    end

    context "失敗時" do
      before {
        allow(order_ask).to receive(:update_execution).and_return(false)
      }

      it { is_expected.to be_falsey }
    end
  end
end
