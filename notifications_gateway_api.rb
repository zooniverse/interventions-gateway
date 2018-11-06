require 'sinatra/base'
require 'ostruct'
require 'pry' if ['test', 'development'].include?(ENV['RACK_ENV'])

require_relative 'lib/sugar'
require_relative 'lib/credential'
require_relative 'lib/version'

SORTED_MESSAGE_KEYS = %w(message project_id user_id).freeze
SORTED_SUBJECT_QUEUE_KEYS = %w(project_id subject_ids user_id workflow_id).freeze
INTERVENTION_EVENT = { event: 'Intervention' }.freeze

class Intervention < OpenStruct
  def initialize(params)
    super(params.merge(INTERVENTION_EVENT))
  end
end

class NotificationsGatewayApi < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  before do
    content_type 'application/json'
    setup_credentials if request.post?
  end

  # {
  #   "message": "All of your contributions really help."
  #   "project_id": "5733",
  #   "user_id": "6"
  # }
  post '/messages' do
    json = JSON.parse(request.body.read.to_s)

    valid_payload = SORTED_MESSAGE_KEYS == json.keys.sort

    unless valid_payload
      halt 422, 'message requires message, project_id and user_id attributes'
    end

    message = Intervention.new(json)

    authorize(message) do
      sugar_client.experiment(message.to_h)
    end
  end

  # {
  #   "project_id": "3434",
  #   "subject_ids": ["1", "2"],
  #   "user_id": "23",
  #   "workflow_id": "21"
  # }
  post '/subject_queues' do
    json = JSON.parse(request.body.read.to_s)

    valid_payload = SORTED_SUBJECT_QUEUE_KEYS == json.keys.sort

    unless valid_payload
      halt 422, 'subject_queues requires project_id, subject_ids, user_id and workflow_id attributes'
    end

    subject_queue_req = Intervention.new(json)

    authorize(subject_queue_req) do
      sugar_client.experiment(subject_queue_req.to_h)
    end
  end

  # add a default health check end point
  get '/' do
    {status: 'ok', version: VERSION}.to_json
  end

  private

  def sugar_client
    @sugar_client ||= Sugar.new(
      ENV['SUGAR_HOST'],
      ENV['SUGAR_USERNAME'],
      ENV['SUGAR_PASSWORD']
    )
  end

  def setup_credentials
    authorization = request.env['HTTP_AUTHORIZATION']
    match = /\ABearer (.*)\Z/.match(authorization)

    if match
      auth = match[1]
      @credential = Credential.new(auth)
    else
      halt 401
    end
  end

  def authorize(request)
    if @credential.accessible_project?(request.project_id)
      yield
      success_response(request.user_id)
    else
      halt 403, 'You do not have access to this project'
    end
  end

  def success_response(user_id)
    {
      status: "ok",
      message: "message sent to user_id: #{user_id}"
    }.to_json
  end
end
