# frozen_string_literal: true
require "securerandom"

module Extension
  module ExtensionTestHelpers
    module Stubs
      module CreateExtension
        include TestHelpers::Partners

        def stub_create_extension(api_key:, specification_identifier:, title:, config:, extension_context: nil)
          stub_partner_req(
            "extension_create",
            variables: {
              api_key: api_key,
              specification_identifier: specification_identifier,
              title: title,
              config: JSON.generate(config),
              extension_context: extension_context,
            },
            resp: {
              data: yield(title, specification_identifier, config, extension_context),
            }
          )
        end

        def stub_create_extension_success(**args)
          registration_id = rand(9999)
          registration_uuid = SecureRandom.uuid
          stub_create_extension(**args) do |title, specification_identifier|
            {
              extensionCreate: {
                extensionRegistration: {
                  id: registration_id,
                  uuid: registration_uuid,
                  specificationIdentifier: specification_identifier,
                  title: title,
                  draftVersion: {
                    registrationId: registration_id,
                    lastUserInteractionAt: Time.now.utc.to_s,
                  },
                },
                userErrors: [],
              },
            }
          end
        end

        def stub_create_extension_failure(userErrors:, **args) # rubocop:disable Naming/VariableName
          stub_create_extension(**args) do
            {
              extensionCreate: {
                userErrors: userErrors, # rubocop:disable Naming/VariableName
              },
            }
          end
        end
      end
    end
  end
end
