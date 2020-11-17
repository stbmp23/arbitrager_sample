# frozen_string_literal: true

require 'bundler'
require 'io/console'
require 'dotenv'
Dotenv.load

libpath = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(libpath) unless $LOAD_PATH.include?(libpath)

env = ENV.fetch('ENVIRONMENT', :development)

Bundler.require(:default, env)
Time.zone = 'Asia/Tokyo'
Config.load_and_set_settings(
  Config.setting_files(File.expand_path('../../config', __FILE__), env)
)

require 'arbitrager'
