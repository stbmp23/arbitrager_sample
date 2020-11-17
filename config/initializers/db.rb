# frozen_string_literal: true

config = YAML::load(ERB.new(IO.read(File.expand_path('../../database.yml', __FILE__))).result)
env = ENV.fetch('ENVIRONMENT', 'development')
ActiveRecord::Base.establish_connection(config[env])
ActiveRecord::Base.time_zone_aware_attributes = true
