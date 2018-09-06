dev_env = 'development'
env = ENV['RACK_ENV'] || dev_env
port = env == dev_env ? 3000 : 80
environment env

if env == "production" || env == "staging"
  stdout_redirect 'log/api.log', 'log/api_err.log', true
end

bind "tcp://0.0.0.0:#{port}"
