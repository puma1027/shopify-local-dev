# frozen_string_literal: true
require "shopify_cli"

module Extension
  class ExtensionProject < ShopifyCli::Project
    class << self
      def write_cli_file(context:, type:)
        ShopifyCli::Project.write(
          context,
          project_type: :extension,
          organization_id: nil,
          "#{ExtensionProjectKeys::SPECIFICATION_IDENTIFIER_KEY}": type
        )
      end

      def write_env_file(
        context:, title:, api_key: "", api_secret: "", registration_id: nil, registration_uuid: nil
      )
        ShopifyCli::Resources::EnvFile.new(
          api_key: api_key,
          secret: api_secret,
          extra: {
            ExtensionProjectKeys::TITLE_KEY => title,
            ExtensionProjectKeys::REGISTRATION_ID_KEY => registration_id,
            ExtensionProjectKeys::REGISTRATION_UUID_KEY => registration_uuid || generate_temporary_uuid,
          }.compact
        ).write(context)

        reload
      end

      def reload
        current.reload unless project_empty?
      end

      private

      def project_empty?
        directory(Dir.pwd).nil?
      end
    end

    def app
      Models::App.new(api_key: env["api_key"], secret: env["secret"])
    end

    def registered?
      property_present?("api_key") && property_present?("secret") && registration_id?
    end

    def title
      get_extra_field(ExtensionProjectKeys::TITLE_KEY)
    end

    def specification_identifier
      config[ExtensionProjectKeys::SPECIFICATION_IDENTIFIER_KEY]
    end

    def registration_id?
      extra_property_present?(ExtensionProjectKeys::REGISTRATION_ID_KEY) &&
        integer?(get_extra_field(ExtensionProjectKeys::REGISTRATION_ID_KEY)) &&
        registration_id > 0
    end

    def registration_id
      get_extra_field(ExtensionProjectKeys::REGISTRATION_ID_KEY).to_i
    end

    def registration_uuid
      get_extra_field(ExtensionProjectKeys::REGISTRATION_UUID_KEY)
    end

    def reload
      @env = nil
    end

    def self.generate_temporary_uuid
      "dev-#{SecureRandom.uuid}"
    end

    private

    def get_extra_field(key)
      extra = env[:extra] || {}
      extra[key]
    end

    def extra_property_present?(key)
      env[:extra].key?(key) && !get_extra_field(key).nil?
    end

    def property_present?(key)
      !env[key].nil? && !env[key].strip.empty?
    end

    def integer?(value)
      value.to_i.to_s == value.to_s
    end
  end
end
