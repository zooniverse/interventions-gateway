module Env
  def self.deployed?
    !local?
  end

  def self.local?
    ['test', 'development'].include?(ENV['RACK_ENV'])
  end

  def self.environment
    ENV.fetch('RACK_ENV', 'development')
  end

  def self.rollbar_token
    ENV.fetch('ROLLBAR_TOKEN', '')
  end
end
