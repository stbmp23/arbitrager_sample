# frozen_string_literal: true

# 各brokerで共通で使用する関数
module Arbitrager
  module Broker
    def id
      @config.id.to_i
    end

    def name
      @config.name
    end

    def code
      @config.name.downcase.to_sym
    end

    def commission_percent
      @config.commission_percent
    end

    def priority
      @config.priority
    end

    def enable?
      @config.enable
    end

    def key
      @key ||= decrypt(@account['key'])
    end

    def secret
      @secret ||= decrypt(@account['secret'])
    end

    private

    def decrypt(encrypted_data)
      encrypted_data = Array.new([encrypted_data]).pack("H*")

      dec = OpenSSL::Cipher.new(ENV['OPENSSL_TYPE'])
      dec.decrypt
      dec.key = Arbitrager.brokers.key + ENV['OPENSSL_KEY']
      dec.iv = ENV['OPENSSL_IV']

      dec.update(encrypted_data) + dec.final
    end
  end
end

