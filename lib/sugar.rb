require 'faraday'
require 'faraday_middleware'

class Sugar
  def initialize(url)
  end

  def self.config
    @config ||= {
      host: ENV['SUGAR_HOST'],
      username: ENV['SUGAR_USERNAME'],
      password: ENV['SUGAR_PASSWORD']
    }
  end

  def self.connection
    @connection ||= Faraday.new(config[:host]) do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.basic_auth config[:username], config[:password]
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.request(method, path, *args)
    connection.send(method, path, *args) do |req|
      req.headers['Accept'] = 'application/json'
      req.headers['Content-Type'] = 'application/json'
      yield req if block_given?
    end
  rescue URI::BadURIError => e
    ::Rails.logger.warn 'Sugar configuration is not valid'
  end

  def self.notify(*notifications)
    request :post, '/notify', { notifications: notifications }.to_json
  end

  def self.announce(*announcements)
    request :post, '/announce', { announcements: announcements }.to_json
  end
end
