# frozen_string_literal: true

module Arbitrager
  module Models
    class Exchange < ActiveRecord::Base
      has_many :orders
    end
  end
end

