require 'panoptes-client'

# Wrapper around the authentication token given by API consumers.
class Credential
  OWNER_ROLES = %w[owner collaborator].freeze

  attr_reader :token

  def initialize(token)
    @token = token
  end

  def logged_in?
    if user_login
      true
    else
      false
    end
  rescue JWTDecoder::InvalidToken
    false
  end

  def expired?
    expires_at < Time.now.utc
  rescue JWTDecoder::InvalidToken
    true
  end

  def accessible_project?(id)
    api_response = client.panoptes.paginate(
      '/projects',
      {
        id: id,
        current_user_roles: OWNER_ROLES,
        cards: true
      }
    )

    if api_response["projects"].empty?
      false
    else
      true
    end
  end

  private

  def client
    @client ||= Panoptes::Client.new(env: panoptes_client_env, auth: { token: token })
  end

  def panoptes_client_env
    ENV["RACK_ENV"]
  end

  def jwt_payload
    @decoder ||= JWTDecoder.new(token, client)
    @decoder.payload
  end

  def user_login
    @user_login ||= jwt_payload.dig('data', 'login')
  end

  def expires_at
    @expires_at ||= Time.at(jwt_payload['exp'])
  end

  class JWTDecoder
    class InvalidToken < StandardError; end

    attr_reader :token, :client

    def initialize(token, client)
      @token = token
      @client = client
    end

    def payload
      @payload ||= decode_payload
    end

    private

    def decode_payload
      payload, _ = JWT.decode(
        token,
        client.jwt_signing_public_key,
        algorithm: 'RS512'
      )
      payload
    rescue JWT::ExpiredSignature, JWT::VerificationError
      raise InvalidToken
    end
  end
end
