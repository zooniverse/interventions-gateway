require 'spec_helper.rb'

describe "NotificationsGatewayApi" do
  let(:credential) { instance_double(Credential) }

  describe "/" do
    it "should return a health check response" do
      get '/'
      response = {"status"=>"ok", "version"=>VERSION}
      expect(last_response.body).to eq(response.to_json)
    end

    it "should have the json content type" do
      get '/'
      expect(last_response.header["Content-Type"]).to eq("application/json")
    end
  end

  describe "/subject_queues" do
    let(:headers) do
      {'HTTP_AUTHORIZATION' => 'Bearer FakeToken'}
    end
    let(:project_id) { "3434" }
    let(:payload) do
      {
        "type": "subject_queue",
        "project_id": project_id,
        "user_id": "23",
        "subject_ids": ["1", "2"],
        "workflow_id": "21"
      }
    end
    let(:json_payload) do
      payload.to_json
    end

    before do
      allow(Credential).to receive(:new).and_return(credential)
    end

    it "should respond with unauthorized without auth headers" do
      post '/subject_queues', json_payload
      expect(last_response).to be_unauthorized
    end

    context "with a token missing access roles on the project" do
      before do
        expect(credential)
          .to receive(:accessible_project?)
          .with(project_id)
          .and_return(false)
      end

      it "should respond with forbidden" do
        post '/subject_queues', json_payload, headers
        expect(last_response).to be_forbidden
      end
    end

    context "with a token having access roles on the project" do
      before do
        expect(credential)
          .to receive(:accessible_project?)
          .with(project_id)
          .and_return(true)
      end

      it "should respond with ok" do
        allow(SUGAR).to receive(:experiment)
        post '/subject_queues', json_payload, headers
        expect(last_response).to be_ok
      end

      it "should forward the request to sugar client" do
        expect(SUGAR).to receive(:experiment).with(payload)
        post '/subject_queues', json_payload, headers
        expect(last_response).to be_ok
      end
    end
  end
end
