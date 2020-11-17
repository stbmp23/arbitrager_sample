# frozen_string_literal: true

require 'uri'
require 'json'
require 'pathname'
require 'openssl'
require 'jwt'
require 'digest/md5'
require 'active_support/core_ext'
require 'arbitrager/environment'
require 'arbitrager/configurable'
require 'arbitrager/clients'
require 'arbitrager/board/analyzer'
require 'arbitrager/brokers'
require 'arbitrager/boards'
require 'arbitrager/position'
require 'arbitrager/error'
require 'arbitrager/logger'
require 'arbitrager/exchanger'
require 'arbitrager/orders/all'
require 'arbitrager/balancer'

module Arbitrager
  class << self
    include Arbitrager::Configurable

    def root
      @root ||= Pathname.new(File.expand_path('../..', __FILE__))
    end

    def env
      @env ||= Arbitrager::Environment.new
    end

    def configure(password)
      @bcrypt = BCrypt::Password.new(ENV["APP_PASSWORD"])
      if @bcrypt != password
        raise "Password is wrong. Exit application."
      end

      self.configuration_load!
      self.brokers.key = password
    end

    def redis
      @redis
    end

    def logger
      @logger ||= Arbitrager::Logger::Log.new
    end

    def clients
      @clients ||= Arbitrager::Clients.new
    end

    def brokers
      @brokers ||= Arbitrager::Brokers.new
    end

    def boards
      @boards ||= Arbitrager::Boards.new
    end

    def analyzer
      @analyzer ||= Arbitrager::Board::Analyzer.new
    end

    def balancer
      @balancer ||= Arbitrager::Balancer.new
    end

    def run
      Arbitrager.logger.info('Start Arbitrage')

      Arbitrager.logger.info('資産状況の更新')
      balancer.refresh!
      balancer.info
      balancer.save_history

      while true
        # 板解析を行う
        analyzer.refresh!
        # 解析結果の情報を表示
        analyzer.info

        # 指定値以上の利益が出る場合は取引を行う
        exchange! if analyzer.can_exchange?

        sleep_time = 3
        Arbitrager.logger.debug("Complete! wait #{sleep_time} seconds...\n")
        sleep(sleep_time)
      end
    end

    private

    # 取引実行
    def exchange!
      # 売り注文
      bid_class = "Arbitrager::Orders::#{analyzer.best_bid.broker.name.classify}".constantize
      # 買い注文
      ask_class = "Arbitrager::Orders::#{analyzer.best_ask.broker.name.classify}".constantize

      # 売り注文
      bid_order = bid_class.create_bid(analyzer.best_bid.price, analyzer.target_position.target_volume)
      # 買い注文
      ask_order = ask_class.create_ask(analyzer.best_ask.price, analyzer.target_position.target_volume)

      exchanger = Arbitrager::Exchanger.new(ask_order, bid_order)
      # APIを使って取引を行う
      #exchanger.start!

      # 資産状況を更新する
      balances = balancer.balances.map { |b| { broker: b.broker, jpy: b.jpy, btc: b.btc } }
      balancer.refresh!
      balancer.save_history(exchange_id: exchanger.model.id, before_balances: balances)
      balancer.info

      puts "取引実行結果: #{exchanger.model.result}"
    end
  end
end
