dev_env = 'development'
env = ENV['RACK_ENV'] || dev_env
port = env == dev_env ? 3000 : 80
environment env
bind "tcp://0.0.0.0:#{port}"
