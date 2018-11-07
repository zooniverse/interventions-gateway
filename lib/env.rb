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
end
