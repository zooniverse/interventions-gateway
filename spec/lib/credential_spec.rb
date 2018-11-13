require 'spec_helper.rb'

describe "Credential" do
  let(:token) { "fake_token" }
  let(:credential) { Credential.new(token) }

  before do
    # override the client env to ensure there is a signing key for decoding
    allow(credential)
    .to receive(:panoptes_client_env)
    .and_return("production")
  end

  describe "logged_in?" do
    before do
      allow(JWT).to receive(:decode).and_return(payload)
    end

    context "with a valid token" do
      let(:payload) do
        { 'data' => { 'login' => 'test-user' } }
      end

      it "should pass" do
        expect(credential.logged_in?).to eq(true)
      end
    end

    context "with a token missing the login attribute" do
      let(:payload) do
        { 'data' => { 'id' => 1 } }
      end

      it "should fail" do
        expect(credential.logged_in?).to eq(false)
      end
    end
  end

  describe "expired?" do
    before do
      allow(JWT).to receive(:decode).and_return(payload)
    end

    context "with a non expired token" do
      let(:one_minute) { 60 }
      let(:payload) do
        { 'exp' => (Time.now + one_minute).utc.to_i }
      end

      it "should be false" do
        expect(credential.expired?).to eq(false)
      end
    end

    context "with a non expired token" do
      let(:three_hours) { 3 * 60 * 60 }
      let(:payload) do
        { 'exp' => (Time.now - three_hours).utc.to_i }
      end

      it "should be true" do
        expect(credential.expired?).to eq(true)
      end
    end

    context "with a token that can't be decoded" do
      let(:payload) { {} }

      it "should be true" do
        allow(JWT).to receive(:decode).and_raise(JWT::ExpiredSignature)
        expect(credential.expired?).to eq(true)
      end
    end
  end

  describe "accessible_project?" do
    let(:client_double) do
      instance_double("Panoptes::Client", panoptes: page_double)
    end

    before do
      allow(Panoptes::Client).to receive(:new).and_return(client_double)
    end

    context "with correct roles on the project for the supplied token" do
      let(:response) do
        {
          "projects"=> [{"id"=>"1"}]
        }
      end
      let(:page_double) { double(paginate: response) }

      it "should pass" do
        expect(credential.accessible_project?(1)).to eq(true)
      end
    end

    context "with no correct roles on the project for the supplied token" do
      let(:response) { { "projects"=> [] } }
      let(:page_double) { double(paginate: response) }

      it "should fail" do
        expect(credential.accessible_project?(1)).to eq(false)
      end
    end
  end
end
