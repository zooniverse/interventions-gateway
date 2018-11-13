require 'spec_helper.rb'

describe "Credential", :focus do
  describe "logged_in?" do
    it "should pass" do
      pending
    end

    it "should fail when missing a user-id" do
      pending
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
