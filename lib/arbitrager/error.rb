# frozen_string_literal: true

module Arbitrager
  class Error < StandardError
    def initialize(message = nil)
      logging
      super(message || 'error!')
    end

    def logging
      # TODO: どっかログに出す
    end
  end
end

require 'arbitrager/error/api_response_error'
require 'arbitrager/error/net_exposure_error'
require 'arbitrager/error/api_validation_error'
