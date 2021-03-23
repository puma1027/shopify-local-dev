# frozen_string_literal: true

module Script
  module Layers
    module Infrastructure
      module Errors
        class AppNotInstalledError < ScriptProjectError; end
        class AppScriptNotPushedError < ScriptProjectError; end
        class AppScriptUndefinedError < ScriptProjectError; end
        class BuildError < ScriptProjectError; end
        class ConfigUiSyntaxError < ScriptProjectError; end

        class ConfigUiMissingKeysError < ScriptProjectError
          attr_reader :filename, :missing_keys
          def initialize(filename, missing_keys)
            super()
            @filename = filename
            @missing_keys = missing_keys
          end
        end

        class ConfigUiFieldsMissingKeysError < ScriptProjectError
          attr_reader :filename, :missing_keys
          def initialize(filename, missing_keys)
            super()
            @filename = filename
            @missing_keys = missing_keys
          end
        end

        class DependencyInstallError < ScriptProjectError; end
        class EmptyResponseError < ScriptProjectError; end
        class ForbiddenError < ScriptProjectError; end

        class GraphqlError < ScriptProjectError
          attr_reader :errors
          def initialize(errors)
            @errors = errors
            super("GraphQL failed with errors: #{errors}")
          end
        end

        class ProjectCreatorNotFoundError < ScriptProjectError; end

        class ScriptRepushError < ScriptProjectError
          attr_reader :api_key
          def initialize(api_key)
            super()
            @api_key = api_key
          end
        end

        class ScriptServiceUserError < ScriptProjectError
          def initialize(query_name, errors)
            super("Failed performing #{query_name}. Errors: #{errors}.")
          end
        end

        class ShopAuthenticationError < ScriptProjectError; end
        class ShopScriptConflictError < ScriptProjectError; end
        class ShopScriptUndefinedError < ScriptProjectError; end
        class TaskRunnerNotFoundError < ScriptProjectError; end
        class BuildScriptNotFoundError < ScriptProjectError; end
        class InvalidBuildScriptError < ScriptProjectError; end

        class WebAssemblyBinaryNotFoundError < ScriptProjectError
          def initialize
            super("WebAssembly binary not found")
          end
        end
      end
    end
  end
end
