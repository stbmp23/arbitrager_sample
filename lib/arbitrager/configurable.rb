# frozen_string_literal: true

require 'yaml'
require 'erb'

module Arbitrager
  module Configurable
    attr_reader :config

    def configuration_load!
      @config = {}
      self.account_configuration
      self.database_configuration
      self.redis_configuration

      self.database_initialize
      self.redis_initialize
    end

    def environment
      Arbitrager.env.environment
    end

    # アカウントの設定
    def account_configuration
      file = Arbitrager.root.join('config', 'account.yml')
      @config[:account] = YAML::load(ERB.new(IO.read(file)).result)
    end

    # データベースの設定
    def database_configuration
      file = Arbitrager.root.join('config', 'database.yml')
      @config[:database] ||= YAML::load(ERB.new(IO.read(file)).result)[environment]
    end

    # Redis設定読み込み
    def redis_configuration
      file = Arbitrager.root.join('config', 'redis.yml')
      @config[:redis] ||= YAML::load(ERB.new(IO.read(file)).result)[environment]
    end

    # データベース
    def database_initialize
      ActiveRecord::Base.establish_connection(@config[:database])
      ActiveRecord::Base.time_zone_aware_attributes = true
      ActiveRecord::Base.default_timezone = :local

      # modelの読み込み
      Dir[Arbitrager.root.join('lib/arbitrager/models/*.rb')].each do |model_file|
        require model_file
      end
    end

    # Redis
    def redis_initialize
      config = @config[:redis]

      @redis = Redis.new(
        host: config['host'],
        port: config['port'],
        db: config['db'],
        password: config['password']
      )
    end
  end
end
