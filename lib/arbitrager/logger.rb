# frozen_string_literal: true

require 'logger'

module Arbitrager
  module Logger
    class Log
      def initialize
        @dir = Arbitrager.root.join('log')
        file = File.join(@dir, 'arbitrager.log')

        output = ENV['ENVIRONMENT'] == 'test' ? nil : STDOUT
        level = ::Logger::DEBUG
        if Arbitrager.environment == 'production'
          output = file
          level = ::Logger::INFO
        end

        @logger = ::Logger.new(output)
        @logger.level = level
      end

      def debug(message)
        @logger.debug(message)
      end

      def info(message)
        @logger.info(message)
      end

      def warn(message)
        @logger.warn(message)
      end

      def error(error = nil, message = nil)
        if error
          message = "#{message}\n#{error.inspect}\n#{error.backtrace.join("\n")}"
        end

        @logger.error(message)
      end

      def fatal(error = nil, message = nil)
        if error
          message = "#{message}\n#{error.inspect}\n#{error.backtrace.join("\n")}"
        end

        @logger.fatal(message)
      end
    end
  end
end
