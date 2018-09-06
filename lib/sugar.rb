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

  def experiment(*events)
    request :post, '/experiment', { experiments: events }.to_json
  end

  def notify(*events)
    request :post, '/notify', { notifications: events }.to_json
  end

  def announce(*events)
    request :post, '/announce', { announcements: events }.to_json
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
