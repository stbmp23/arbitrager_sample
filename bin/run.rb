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
Arbitrager.run
