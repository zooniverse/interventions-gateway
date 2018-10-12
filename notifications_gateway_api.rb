require 'sinatra/base'
require 'ostruct'

require_relative 'lib/sugar'
require_relative 'lib/credential'

class Notification < OpenStruct
end

class SubjectQueue < OpenStruct
end

SUGAR ||= Sugar.new(ENV['SUGAR_HOST'], ENV['SUGAR_USERNAME'], ENV['SUGAR_PASSWORD'])

class NotificationsGatewayApi < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  before do
    authorization = request.env['HTTP_AUTHORIZATION']
    match = /\ABearer (.*)\Z/.match(authorization)

    if match
      auth = match[1]
      @credential = Credential.new(auth)
    else
      halt 401
    end
  end

  before do
    content_type 'application/json'
  end

  # {
  #   "type": "notification",
  #   "project_id": "5733",
  #   "user_id": "6",
  #   "message": "All of your contributions really help."
  # }
  post '/notifications' do
    json = JSON.parse(request.body.read.to_s)
    notification = Notification.new(json)

    if @credential.accessible_project?(notification.project_id)
      SUGAR.experiment(notification.to_h)
      {status: 'ok'}.to_json
    else
      halt 403, {status: 'error', error: 'You do not have access to this project'}.to_json
    end
  end

  # {
  #   "type": "subject_queue",
  #   "project_id": "3434",
  #   "user_id": "23",
  #   "subject_ids": ["1", "2"],
  #   "workflow_id": "21"
  # }
  post '/subject_queues' do
    json = JSON.parse(request.body.read.to_s)
    notification = Notification.new(json)

    if @credential.accessible_project?(notification.project_id)
      SUGAR.experiment(notification.to_h)
    else
      halt 401
    end
  end
end
