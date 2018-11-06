require 'spec_helper.rb'

describe "NotificationsGatewayApi" do
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

  context "when supplying tokens" do
    let(:headers) do
      {'HTTP_AUTHORIZATION' => 'Bearer FakeToken'}
    end
    let(:json_payload) { payload.to_json }
    let(:credential) { instance_double(Credential) }
    let(:sugar) { instance_double(Sugar) }
    let(:project_id) { "3434" }

    before do
      allow(Credential).to receive(:new).and_return(credential)
      allow(Sugar).to receive(:new).and_return(sugar)
    end

    def sugar_intervention_payload(payload)
      payload.merge({
        event: 'Intervention'
      })
    end

    def payload_without_key(payload, key)
      payload.reject { |k,v| k == key }
    end

    describe "/subject_queues" do
      let(:payload) do
        {
          "project_id": project_id,
          "user_id": "23",
          "subject_ids": ["1", "2"],
          "workflow_id": "21"
        }
      end

      it "should respond with unauthorized without auth headers" do
        post '/subject_queues', json_payload
        expect(last_response).to be_unauthorized
      end

      it "should respond with unprocessable with extra payload information" do
        post '/subject_queues', payload.merge(not_needed: "true").to_json, headers
        expect(last_response).to be_unprocessable
      end

      %i(project_id subject_ids user_id workflow_id).each do |attribute|
        it "should respond with unprocessable without #{attribute} param" do
          post '/subject_queues', payload_without_key(payload, attribute).to_json, headers
          expect(last_response).to be_unprocessable
        end
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
          allow(sugar).to receive(:experiment)
          post '/subject_queues', json_payload, headers
          expect(last_response).to be_ok
        end

        it "should forward the request to sugar client" do
          expect(sugar).to receive(:experiment).with(sugar_intervention_payload(payload))
          post '/subject_queues', json_payload, headers
          expect(last_response).to be_ok
        end
      end
    end

    describe "/messages" do
      let(:payload) do
        {
          "project_id": project_id,
          "user_id": "6",
          "message": "All of your contributions really help."
        }
      end

      it "should respond with unauthorized without auth headers" do
        post '/messages', json_payload
        expect(last_response).to be_unauthorized
      end

      it "should respond with unprocessable with extra payload information" do
        post '/messages', payload.merge(not_needed: "true").to_json, headers
        expect(last_response).to be_unprocessable
      end

      %i(project_id message user_id).each do |attribute|
        it "should respond with unprocessable without {#{attribute}} param" do
          post '/messages', payload_without_key(payload, attribute).to_json, headers
          expect(last_response).to be_unprocessable
        end
      end

      context "with a token missing access roles on the project" do
        before do
          expect(credential)
            .to receive(:accessible_project?)
            .with(project_id)
            .and_return(false)
        end

        it "should respond with forbidden" do
          post '/messages', json_payload, headers
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
          allow(sugar).to receive(:experiment)
          post '/messages', json_payload, headers
          expect(last_response).to be_ok
        end

        it "should forward the request to sugar client" do
          expect(sugar).to receive(:experiment).with(sugar_intervention_payload(payload))
          post '/messages', json_payload, headers
          expect(last_response).to be_ok
        end
      end
    end
  end
end
