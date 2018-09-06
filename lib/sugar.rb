require 'uri'
require 'faraday'
require 'faraday_middleware'

class Sugar
  attr_reader :host, :username, :password

  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
  end

  def notify(*notifications)
    request :post, '/notify', { notifications: notifications }.to_json
  end

  def announce(*announcements)
    request :post, '/announce', { announcements: announcements }.to_json
  end

  private

  def connection
    @connection ||= Faraday.new(host) do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.basic_auth username, password
      faraday.adapter Faraday.default_adapter
    end
  end

  def request(method, path, *args)
    connection.send(method, path, *args) do |req|
      req.headers['Accept'] = 'application/json'
      req.headers['Content-Type'] = 'application/json'
      yield req if block_given?
    end
  rescue URI::BadURIError
    ::Rails.logger.warn 'Sugar configuration is not valid'
  end
end
