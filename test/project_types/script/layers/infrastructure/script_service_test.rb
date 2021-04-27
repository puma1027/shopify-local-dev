# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Infrastructure::ScriptService do
  include TestHelpers::Partners

  let(:ctx) { TestHelpers::FakeContext.new }
  let(:script_service) { Script::Layers::Infrastructure::ScriptService.new(ctx: ctx) }
  let(:api_key) { "fake_key" }
  let(:extension_point_type) { "DISCOUNT" }
  let(:schema_major_version) { "1" }
  let(:schema_minor_version) { "0" }
  let(:use_msgpack) { true }
  let(:config_ui) { Script::Layers::Domain::ConfigUi.new(filename: "filename", content: expected_config_ui_content) }
  let(:expected_config_ui_content) { "content" }
  let(:script_service_proxy) do
    <<~HERE
      query ProxyRequest($api_key: String, $query: String!, $variables: String) {
        scriptServiceProxy(
          apiKey: $api_key
          query: $query
          variables: $variables
        )
      }
    HERE
  end

  describe ".push" do
    let(:script_name) { "foo_bar" }
    let(:script_content) { "(module)" }
    let(:api_key) { "fake_key" }
    let(:uuid) { "uuid" }
    let(:app_script_update_or_create) do
      <<~HERE
        mutation AppScriptUpdateOrCreate(
          $extensionPointName: ExtensionPointName!,
          $title: String,
          $configUi: String,
          $sourceCode: String,
          $language: String,
          $schemaMajorVersion: String,
          $schemaMinorVersion: String,
          $useMsgpack: Boolean
        ) {
          appScriptUpdateOrCreate(
            extensionPointName: $extensionPointName
            title: $title
            configUi: $configUi
            sourceCode: $sourceCode
            language: $language
            schemaMajorVersion: $schemaMajorVersion
            schemaMinorVersion: $schemaMinorVersion
            useMsgpack: $useMsgpack
        ) {
            userErrors {
              field
              message
            }
            appScript {
              appKey
              configSchema
              extensionPointName
              title
            }
          }
        }
      HERE
    end

    before do
      stub_load_query("script_service_proxy", script_service_proxy)
      stub_load_query("app_script_update_or_create", app_script_update_or_create)
      stub_partner_req(
        "script_service_proxy",
        variables: {
          api_key: api_key,
          variables: {
            extensionPointName: extension_point_type,
            title: script_name,
            configUi: expected_config_ui_content,
            sourceCode: Base64.encode64(script_content),
            language: "AssemblyScript",
            force: false,
            schemaMajorVersion: schema_major_version,
            schemaMinorVersion: schema_minor_version,
            useMsgpack: use_msgpack,
          }.to_json,
          query: app_script_update_or_create,
        },
        resp: response
      )
    end

    subject do
      script_service.push(
        extension_point_type: extension_point_type,
        metadata: Script::Layers::Domain::Metadata.new(
          schema_major_version,
          schema_minor_version,
          use_msgpack,
        ),
        script_name: script_name,
        script_content: script_content,
        compiled_type: "AssemblyScript",
        config_ui: config_ui,
        api_key: api_key,
      )
    end

    describe "when push to script service succeeds" do
      let(:script_service_response) do
        {
          "data" => {
            "appScriptUpdateOrCreate" => {
              "appScript" => {
                "apiKey" => "fake_key",
                "configSchema" => nil,
                "extensionPointName" => extension_point_type,
                "title" => "foo2",
                "uuid" => uuid
              },
              "userErrors" => [],
            },
          },
        }
      end

      let(:response) do
        {
          data: {
            scriptServiceProxy: JSON.dump(script_service_response),
          },
        }
      end

      it "should post the form without scope" do
        assert_equal(uuid, subject)
      end

      describe "when config_ui is nil" do
        let(:config_ui) { nil }
        let(:expected_config_ui_content) { nil }

        it "should succeed with a valid response" do
          assert_equal(uuid, subject)
        end
      end
    end

    describe "when push to script service responds with errors" do
      let(:response) do
        {
          data: {
            scriptServiceProxy: JSON.dump("errors" => [{ message: "errors" }]),
          },
        }
      end

      it "should raise error" do
        assert_raises(Script::Layers::Infrastructure::Errors::GraphqlError) { subject }
      end
    end

    describe "when partners responds with errors" do
      let(:response) do
        {
          errors: [{ message: "some error message" }],
        }
      end

      it "should raise error" do
        assert_raises(Script::Layers::Infrastructure::Errors::GraphqlError) { subject }
      end
    end

    describe "when push to script service responds with userErrors" do
      describe "when invalid app key" do
        let(:response) do
          {
            data: {
              scriptServiceProxy: JSON.dump(
                "data" => {
                  "appScriptUpdateOrCreate" => {
                    "userErrors" => [{ "message" => "invalid", "field" => "appKey", "tag" => "user_error" }],
                  },
                }
              ),
            },
          }
        end

        it "should raise error" do
          assert_raises(Script::Layers::Infrastructure::Errors::GraphqlError) { subject }
        end
      end

      describe "when repush without a force" do
        let(:response) do
          {
            data: {
              scriptServiceProxy: JSON.dump(
                "data" => {
                  "appScriptUpdateOrCreate" => {
                    "userErrors" => [{ "message" => "error", "tag" => "already_exists_error" }],
                  },
                }
              ),
            },
          }
        end

        it "should raise ScriptRepushError error" do
          assert_raises(Script::Layers::Infrastructure::Errors::ScriptRepushError) { subject }
        end
      end

      describe "when metadata is invalid" do
        let(:response) do
          {
            data: {
              scriptServiceProxy: JSON.dump(
                "data" => {
                  "appScriptUpdateOrCreate" => {
                    "userErrors" => [{ "message" => "error", "tag" => error_tag }],
                  },
                }
              ),
            },
          }
        end

        describe "when not using msgpack" do
          let(:error_tag) { "not_use_msgpack_error" }
          it "should raise MetadataValidationError error" do
            assert_raises(Script::Layers::Domain::Errors::MetadataValidationError) { subject }
          end
        end

        describe "when invalid schema version" do
          let(:error_tag) { "schema_version_argument_error" }
          it "should raise MetadataValidationError error" do
            assert_raises(Script::Layers::Domain::Errors::MetadataValidationError) { subject }
          end
        end
      end

      describe "when response is empty" do
        let(:response) { nil }

        it "should raise EmptyResponseError error" do
          assert_raises(Script::Layers::Infrastructure::Errors::EmptyResponseError) { subject }
        end
      end
    end
  end

  private

  def stub_load_query(name, body)
    ShopifyCli::API.any_instance.stubs(:load_query).with(name).returns(body)
  end
end
