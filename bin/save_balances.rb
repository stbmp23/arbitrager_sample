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

while true
  Arbitrager.balancer.refresh!
  Arbitrager.balancer.balances.each do |balance|
    Arbitrager::Models::Balance.create({
      broker_id: balance.broker.id,
      jpy: balance.jpy,
      btc: balance.btc,
    })
  end

  sleep 600
end
