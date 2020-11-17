# frozen_string_literal: true

module Arbitrager
  class Environment

    def initialize
      @environment = ENV['ENVIRONMENT'] || 'development'
    end

    def to_s
      @environment
    end

    def environment
      @environment
    end

    def production?
      @environment == 'production'
    end

    def development?
      @environment == 'development'
    end

    def test?
      @environment == 'test'
    end
  end
end
