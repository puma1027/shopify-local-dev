# frozen_string_literal: true

module Script
  module Layers
    module Infrastructure
      module Errors
        class AppNotInstalledError < ScriptProjectError; end
        class BuilderNotFoundError < ScriptProjectError; end
        class BuildError < ScriptProjectError; end
        class DependencyError < ScriptProjectError; end
        class DependencyInstallError < ScriptProjectError; end
        class ForbiddenError < ScriptProjectError; end
        class GraphqlError < ScriptProjectError
          attr_reader :errors
          def initialize(errors)
            @errors = errors
            super("GraphQL failed with errors: #{errors}")
          end
        end
        class ScriptRedeployError < ScriptProjectError
          attr_reader :api_key
          def initialize(api_key)
            @api_key = api_key
          end
        end
        class ScriptServiceUserError < ScriptProjectError
          def initialize(query_name, errors)
            super("Failed performing #{query_name}. Errors: #{errors}.")
          end
        end
        class ShopAuthenticationError < ScriptProjectError; end
        class TestError < ScriptProjectError; end
      end
    end
  end
end
