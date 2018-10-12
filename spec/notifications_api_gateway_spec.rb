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

    describe "/subject_queues" do
      let(:payload) do
        {
          "type": "subject_queue",
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
          expect(sugar).to receive(:experiment).with(payload)
          post '/subject_queues', json_payload, headers
          expect(last_response).to be_ok
        end
      end
    end

    describe "/notifications" do
      let(:payload) do
        {
          "type": "notification",
          "project_id": project_id,
          "user_id": "6",
          "message": "All of your contributions really help."
        }
      end

      it "should respond with unauthorized without auth headers" do
        post '/notifications', payload.to_json
        expect(last_response).to be_unauthorized
      end

      it "should respond with unprocessable without channel param" do
        post '/notifications', payload.to_json, headers
        expect(last_response).to be_unprocessable
      end

      it "should respond with unprocessable with incorrrect channel param" do
        payload["channel"] = "unknown_channel"
        post '/notifications', payload.to_json, headers
        expect(last_response).to be_unprocessable
        expect(last_response.body).to eq("Please provide a valid channel param values can be 'notification' or 'experiment'")
      end

      context "with valid channels" do
        {experiment: :experiment, notification: :notify}.each do |channel, sugar_method|
          context "with a token missing access roles on the project" do
            before do
              expect(credential)
                .to receive(:accessible_project?)
                .with(project_id)
                .and_return(false)
            end

            it "should respond with forbidden" do
              notify_payload = payload.merge("channel" => channel).to_json
              post '/notifications', notify_payload, headers
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
              allow(sugar).to receive(sugar_method)
              notify_payload = payload.merge("channel" => channel).to_json
              post '/notifications', notify_payload, headers
              expect(last_response).to be_ok
            end

            it "should forward the request to sugar client" do
              expect(sugar).to receive(sugar_method).with(payload)
              notify_payload = payload.merge("channel" => channel).to_json
              post '/notifications', notify_payload, headers
              expect(last_response).to be_ok
            end
          end
        end
      end
    end
  end
end
