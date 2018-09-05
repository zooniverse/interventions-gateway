require 'sinatra/base'
require 'ostruct'
require 'pry'

require_relative 'lib/sugar'
require_relative 'lib/credential'

class Notification < OpenStruct
end

# Main app
class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  before do
    authorization = request.env["HTTP_AUTHORIZATION"]
    match = /\ABearer (.*)\Z/.match(authorization)

    if match
      auth = match[1]
      @credential = Credential.new(auth)
    else
      halt 401
    end
  end

  # {
  #   "type": "notification",
  #   "project_id": "5733",
  #   "user_id": "6",
  #   "message": "All of your contributions really help."
  # }
  post '/notifications' do
    json = JSON.parse(request.body.read.to_s)
    event = Notification.new(json)

    if @credential.accessible_project?(event.project_id)
      'foo'
    else
      halt 401
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
  end
end
