require 'sinatra/base'
require 'ostruct'
require 'rollbar/middleware/sinatra'

require_relative 'lib/sugar'
require_relative 'lib/credential'
require_relative 'lib/version'
require_relative 'lib/env'

require 'pry' if Env.local?

SORTED_MESSAGE_KEYS = %w(message project_id user_id).freeze
OPTIONAL_MESSAGE_KEYS = %w(workflow_id).freeze
SORTED_SUBJECT_QUEUE_KEYS = %w(project_id subject_ids user_id workflow_id).freeze
INTERVENTION_EVENT = { event: 'intervention' }.freeze
MESSAGE_EVENT_TYPE = { event_type: 'message' }.freeze
SUBJECT_QUEUE_EVENT_TYPE = { event_type: 'subject_queue' }.freeze

class InterventionsGatewayApi < Sinatra::Base
  use Rollbar::Middleware::Sinatra

  attr_reader :credential

  configure :production, :staging, :development do
    enable :logging
  end

  before do
    content_type 'application/json'
    if request.post?
      setup_credentials
      unless valid_credentials
        error_response(401, 'invalid credentials, please check your token details')
      end
    end
  end

  # {
  #   "message": "All of your contributions really help."
  #   "project_id": "5733",
  #   "user_id": "6"
  # }
  post '/messages' do
    json = JSON.parse(request.body.read.to_s)

    payload_attributes = json.keys.sort.dup
    non_optional_attributes = payload_attributes - OPTIONAL_MESSAGE_KEYS
    has_required_attributes = (SORTED_MESSAGE_KEYS - non_optional_attributes).empty?
    has_unknown_attributes = !(non_optional_attributes - SORTED_MESSAGE_KEYS).empty?

    valid_payload = has_required_attributes && !has_unknown_attributes

    unless valid_payload
      error_response(
        422,
        'message requires message, project_id and user_id attributes'
      )
    end

    message = Message.new(json)

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
      error_response(422, 'subject_queues requires project_id, subject_ids, user_id and workflow_id attributes')
    end

    subject_queue_req = SubjectQueue.new(json)

    authorize(subject_queue_req) do
      sugar_client.experiment(subject_queue_req.to_h)
    end
  end

  # add a default health check end point
  get '/' do
    {status: 'ok', version: VERSION, commit_id: Env.commit_id}.to_json
  end

  # sinkhole 404 & 400 responses
  error Sinatra::NotFound do
    error_response(404, 'Not Found')
  end

  error Sinatra::BadRequest do
    error_response(400, 'Bad Request')
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
    end
  end

  def valid_credentials
    return false unless credential

    credential.logged_in? && !credential.expired?
  end

  def authorize(message)
    if credential.accessible_project?(message.project_id)
      yield
      success_response(message.user_id, message.uuid)
    else
      error_response(403, 'You do not have access to this project')
    end
  end

  def success_response(user_id, uuid)
    {
      status: "ok",
      message: "payload sent to user_id: #{user_id}",
      uuid: uuid
    }.to_json
  end

  def error_response(status_code, message)
    halt status_code, { errors: [message] }.to_json
  end

  class Intervention < OpenStruct
    def initialize(params)
      uuid_added = params.merge(uuid: SecureRandom.uuid)
      full_payload = uuid_added.merge(INTERVENTION_EVENT)

      super(full_payload)
    end
  end

  class Message < Intervention
    def initialize(params)
      super(params.merge(MESSAGE_EVENT_TYPE))
    end
  end

  class SubjectQueue < Intervention
    def initialize(params)
      super(params.merge(SUBJECT_QUEUE_EVENT_TYPE))
    end
  end
end
