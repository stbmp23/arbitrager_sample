require 'bundler/setup'
require 'dotenv'
Dotenv.load

db_dir = File.expand_path('../db', __FILE__)
config_dir = File.expand_path('../config', __FILE__)

env = ENV.fetch('ENVIRONMENT', 'development')

namespace :db do
  desc 'dump Schemafile'
  task :dump do
    sh "ridgepole -c #{config_dir}/database.yml --env #{env} --export -o #{db_dir}/Schemafile"
  end

  desc 'apply Schemafile and update schema.rb'
  task :apply do
    sh "ridgepole -c #{config_dir}/database.yml --env #{env} --apply -f #{db_dir}/Schemafile"
    if env == 'development'
      sh "ridgepole -c #{config_dir}/database.yml --env test --apply -f #{db_dir}/Schemafile"
    end
  end

  desc 'apply dry-dun'
  task :dry do
    sh "ridgepole -c #{config_dir}/database.yml --env #{env} --apply --dry-run -f #{db_dir}/Schemafile"
    if env == 'development'
      sh "ridgepole -c #{config_dir}/database.yml --env test --apply --dry-run -f #{db_dir}/Schemafile"
    end
  end
end
