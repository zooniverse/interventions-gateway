require 'spec_helper.rb'

describe "InterventionsGatewayApi" do
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

  shared_examples "validates bearer tokens" do
    it "should respond with unauthorized without auth headers" do
      post end_point, json_payload
      expect(last_response).to be_unauthorized
      json_response_body = JSON.parse(last_response.body)
      error_response = {
        "errors" => ["invalid credentials, please check your token details"]
      }
      expect(json_response_body).to eq(error_response)
    end

    context "when token is expired" do
      let(:credential) { instance_double("Credential", expired?: true, logged_in?: true) }

      it "should respond with unauthorized" do
        post end_point, json_payload, headers
        expect(last_response).to be_unauthorized
      end
    end

    context "when token is missing user" do
      let(:credential) { instance_double("Credential", expired?: false, logged_in?: false) }

      it "should respond with unauthorized" do
        post end_point, json_payload, headers
        expect(last_response).to be_unauthorized
      end
    end
  end

  context "when supplying tokens" do
    let(:headers) do
      {'HTTP_AUTHORIZATION' => 'Bearer FakeToken'}
    end
    let(:json_payload) { payload.to_json }
    let(:credential) { instance_double(Credential, expired?: false, logged_in?: true) }
    let(:sugar) { instance_double(Sugar) }
    let(:project_id) { "3434" }

    before do
      allow(Credential).to receive(:new).and_return(credential)
      allow(Sugar).to receive(:new).and_return(sugar)
    end

    def sugar_intervention_payload(payload)
      payload.merge({
        event: 'intervention'
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

      it_behaves_like "validates bearer tokens" do
        let(:end_point) { "/subject_queues" }
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

        it "should respond with a success message" do
          uuid = SecureRandom.uuid
          allow(sugar).to receive(:experiment)
          allow(SecureRandom).to receive(:uuid).and_return(uuid)
          post '/subject_queues', json_payload, headers
          json_response_body = JSON.parse(last_response.body)
          expected_msg = {
            "status"=>"ok",
            "message"=>"payload sent to user_id: 23",
            "uuid"=>uuid
          }
          expect(json_response_body).to eq(expected_msg)
        end

        it "should forward the request to sugar client" do
          sugar_payload = sugar_intervention_payload(
            payload.merge(event_type: 'subject_queue')
          )
          expect(sugar).to receive(:experiment).with(sugar_payload)
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

      it_behaves_like "validates bearer tokens" do
        let(:end_point) { "/messages" }
      end

      it "should respond with unprocessable with extra payload information" do
        post '/messages', payload.merge(not_needed: "true").to_json, headers
        expect(last_response).to be_unprocessable
        json_response_body = JSON.parse(last_response.body)
        expected_msg = {
          "errors" => ["message requires message, project_id and user_id attributes"]
        }
        expect(json_response_body).to eq(expected_msg)
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
          sugar_payload = sugar_intervention_payload(
            payload.merge(event_type: 'message')
          )
          expect(sugar).to receive(:experiment).with(sugar_payload)
          post '/messages', json_payload, headers
          expect(last_response).to be_ok
        end
      end
    end
  end
end
