require 'panoptes-client'

# Wrapper around the authentication token given by API consumers.
class Credential
  OWNER_ROLES = %w[owner collaborator].freeze

  attr_reader :token

  def initialize(token)
    @token = token
  end

  def logged_in?
    return false if jwt_payload.empty?
    jwt_payload.key?('login')
  rescue JWT::ExpiredSignature
    false
  end

  def expired?
    expires_at < Time.zone.now
  end

  def project_ids
    @project_ids ||=
      fetch_accessible_projects['projects'].map { |prj| prj['id'] }
  end

  def accessible_project?(id)
    project_ids.include?(id)
  end

  def accessible_workflow?(id)
    response = client.panoptes.get("/workflows/#{id}")
    workflow_hash = response['workflows'][0]
    project_id = workflow_hash['links']['project'].to_i

    if project_ids.include?(project_id)
      workflow_hash
    end
  rescue Panoptes::Client::ResourceNotFound
    nil
  end

  private

  def jwt_payload
    @jwt_payload ||=
      if token
        client.current_user
      else
        {}
      end
  end

  def client
    @client ||= Panoptes::Client.new(env: panoptes_client_env, auth: { token: token })
  end

  def panoptes_client_env
    ENV["RACK_ENV"]
  end

  def expires_at
    @expires_at ||= begin
                      payload, _ = JWT.decode token, client.jwt_signing_public_key, algorithm: 'RS512'
                      Time.at(payload.fetch('exp'))
                    end
  end

  def fetch_accessible_projects
    puts "Loading accessible projects from Panoptes"
    result = client.panoptes.paginate('/projects', current_user_roles: OWNER_ROLES)

    puts "done"
    result
  end
end
