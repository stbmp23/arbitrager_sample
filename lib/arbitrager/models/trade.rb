# frozen_string_literal: true

module Arbitrager
  module Models
    class Trade < ActiveRecord::Base
      ACTION_ID_ASK = 1
      ACTION_ID_BID = 2

      def ask?
        action_id == ACTION_ID_ASK
      end

      def bid?
        action_id == ACTION_ID_BID
      end

      def action_code
        if ask?
          :ask
        elsif bid?
          :bid
        end
      end
    end
  end
end

