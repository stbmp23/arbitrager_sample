# frozen_string_literal: true

require_relative '../config/boot'

if ENV['DEV_PASS']
  password = ENV["DEV_PASS"]
else
  print "Enter: "
  password = STDIN.noecho(&:gets)
  puts ""
end

# Start Arbitrage
Arbitrager.configure(password.chomp)

class TradeHistory
  def record
    bitflyer
    zaif
    bitbank
  end

  def record_all
    # BitFlyer
    last_order_id = 0
    while true
      last_order_id = bitflyer(before: last_order_id)
      p last_order_id
      break if last_order_id.blank?
      sleep 3
    end

    # Zaif
    last_order_id = 0
    while true
      last_order_id = zaif(from_id: last_order_id)
      p last_order_id
      next if last_order_id == false
      break if last_order_id.blank?
      sleep 3
    end

    # BitBank
    bitbank
  end

  def bitflyer(options = {})
    options.merge!(child_order_state: 'COMPLETED')
    response = Arbitrager.clients.bitflyer.get_orders(options)
    return nil if response.params.blank?
    response.params.each do |order|
      trade = Arbitrager::Models::Trade.find_or_initialize_by(broker_id: Arbitrager.brokers.bitflyer.id, order_id: order['id'])
      trade.update_attributes(
        broker_id: Arbitrager.brokers.bitflyer.id,
        order_acceptance_id: order['child_order_acceptance_id'],
        action_id: order['side'] == 'BUY' ? Arbitrager::Models::Trade::ACTION_ID_ASK : Arbitrager::Models::Trade::ACTION_ID_BID,
        price: order['average_price'],
        volume: order['size'],
        fee: order['total_commission'],
        ordered_at: Time.parse(order['child_order_date']),
      )
    end

    response.params.last['id']
  end

  def zaif(options = {})
    response = Arbitrager.clients.zaif.get_orders(options)
    return nil if response.params['return'].blank?
    response.params['return'].each do |order_id, order|
      trade = Arbitrager::Models::Trade.find_or_initialize_by(broker_id: Arbitrager.brokers.zaif.id, order_id: order_id)
      trade.update_attributes(
        action_id: order['your_action'] == 'bid' ? Arbitrager::Models::Trade::ACTION_ID_ASK : Arbitrager::Models::Trade::ACTION_ID_BID,
        price: order['price'],
        volume: order['amount'],
        fee: order['fee'],
        ordered_at: Time.at(order['timestamp'].to_i),
      )
    end

    response.params['return'].first[0].to_i + 1
  rescue Arbitrager::Error::ApiResponseError => e
    return false
  end

  def bitbank(options = {})
    orders = Arbitrager::Models::Order.joins('LEFT JOIN trades ON orders.order_acceptance_id = trades.order_id')
               .where('trades.order_id': nil, 'orders.broker_id': Arbitrager.brokers.bitbank.id)
    orders.find_in_batches(batch_size: 100) do |order_list|
      order_ids = order_list.pluck(:order_acceptance_id)
      response = Arbitrager.clients.bitbank.get_orders_info(order_ids)

      response.params['data']['orders'].each do |order|
        trade = Arbitrager::Models::Trade.find_or_initialize_by(broker_id: Arbitrager.brokers.bitbank.id, order_id: order['order_id'])
        trade.update_attributes(
          action_id: order['side'] == 'buy' ? Arbitrager::Models::Trade::ACTION_ID_ASK : Arbitrager::Models::Trade::ACTION_ID_BID,
          price: order['average_price'],
          volume: order['executed_amount'],
          fee: 0,
          ordered_at: Time.at(order['ordered_at'].to_i / 1000),
        )
      end
    end
  end
end


th = TradeHistory.new

if ARGV[0] == '--all'
  th.record_all
else
  th.record
end
