require 'spec_helper.rb'

describe "Credential" do
  let(:token) { "fake_token" }
  let(:credential) { Credential.new(token) }

  describe "logged_in?", :focus do
    before do
      allow(Panoptes::Client).to receive(:new).and_return(jwt_payload)
    end

    context "with a valid token" do
      let(:jwt_payload) do
        double(current_user: { 'login' => 'test-user' })
      end

      it "should pass" do
        expect(credential.logged_in?).to eq(true)
      end
    end

    context "with a token missing the login attribute" do
      let(:jwt_payload) do
        double(current_user: { 'id' => 1 })
      end

      it "should fail" do
        expect(credential.logged_in?).to eq(false)
      end
    end
  end

  describe "expired?" do
    it "should pass with a valid token" do
      pending
    end

    it "should fail when token has expired" do
      pending
    end
  end

  describe "accessible_project?" do
    it "should pass with correct roles for token" do
      pending
    end

    it "should fail when i have no roles on project" do
      pending
    end
  end
end
