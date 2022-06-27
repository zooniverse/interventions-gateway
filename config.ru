require_relative 'interventions_gateway_api'

Rollbar.configure do |config|
  enabled = use_async = Env.deployed?
  config.access_token = Env.rollbar_token
  config.environment  = Env.environment
  config.enabled      = enabled
  config.use_async    = use_async
  # do not report these errors to rollbar
  # https://docs.rollbar.com/docs/ruby#exception-level-filters
  config.exception_level_filters.merge!({
    'Sinatra::NotFound' => 'ignore',
    'Sinatra::BadRequest' => 'ignore'
  })
end

run InterventionsGatewayApi
