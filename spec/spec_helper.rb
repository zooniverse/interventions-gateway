# spec/spec_helper.rb
require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../notifications_gateway_api.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() NotificationsGatewayApi end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
