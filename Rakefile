require 'rollbar/rake_tasks'
require_relative 'lib/env'

task :environment do
  Rollbar.configure do |config |
    config.access_token = Env.rollbar_token
  end
end
