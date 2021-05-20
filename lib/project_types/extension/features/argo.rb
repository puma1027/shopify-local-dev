# frozen_string_literal: true
require "base64"
require "shopify_cli"
require "semantic/semantic"

module Extension
  module Features
    class Argo
      include SmartProperties

      property! :git_template, converts: :to_str
      property! :renderer_package_name, converts: :to_str

      SCRIPT_PATH = %w(build main.js).freeze

      NPM_LIST_COMMAND = %w(list).freeze
      YARN_LIST_COMMAND = %w(list).freeze
      NPM_LIST_PARAMETERS = %w(--prod --depth=1).freeze
      YARN_LIST_PARAMETERS = %w(--production).freeze
      private_constant :NPM_LIST_COMMAND, :YARN_LIST_COMMAND, :NPM_LIST_PARAMETERS, :YARN_LIST_PARAMETERS

      YARN_INSTALL_COMMAND = %w(install).freeze
      YARN_INSTALL_PARAMETERS = %w(--silent).freeze
      YARN_RUN_COMMAND = %w(run).freeze
      YARN_RUN_SCRIPT_NAME = %w(build).freeze
      private_constant :YARN_INSTALL_COMMAND, :YARN_INSTALL_PARAMETERS, :YARN_RUN_COMMAND, :YARN_RUN_SCRIPT_NAME

      def create(directory_name, identifier, context)
        Features::ArgoSetup.new(git_template: git_template).call(directory_name, identifier, context)
      end

      def config(context)
        js_system = ShopifyCli::JsSystem.new(ctx: context)
        if js_system.package_manager == "yarn"
          run_yarn_install(context, js_system)
          run_yarn_run_script(context, js_system)
        end
        filepath = File.join(context.root, SCRIPT_PATH)
        context.abort(context.message("features.argo.missing_file_error")) unless File.exist?(filepath)
        begin
          {
            renderer_version: renderer_package(context).version,
            serialized_script: Base64.strict_encode64(File.read(filepath).chomp),
          }
        rescue StandardError
          context.abort(context.message("features.argo.script_prepare_error"))
        end
      end

      def renderer_package(context)
        Features::ArgoRendererPackage.from_package_manager(run_list_command(context))
      rescue Extension::PackageNotFound
        context.abort(
          context.message("features.argo.dependencies.argo_missing_renderer_package_error")
        )
      end

      private

      def run_list_command(context)
        yarn_list = YARN_LIST_COMMAND + YARN_LIST_PARAMETERS
        npm_list = NPM_LIST_COMMAND + NPM_LIST_PARAMETERS

        result, _error, _status = ShopifyCli::JsSystem.call(
          context,
          yarn: yarn_list,
          npm: npm_list,
          capture_response: true
        )
        # context.abort(
        #   context.message("features.argo.dependencies.argo_missing_renderer_package_error", error)
        # ) unless status.success?
        result
      end

      def run_yarn_install(context, js_system)
        _result, error, status = js_system.call(
          yarn: YARN_INSTALL_COMMAND + YARN_INSTALL_PARAMETERS,
          npm: [],
          capture_response: true
        )

        context.abort(
          context.message("features.argo.dependencies.yarn_install_error", error)
        ) unless status.success?
      end

      def run_yarn_run_script(context, js_system)
        _result, error, status = js_system.call(
          yarn: YARN_RUN_COMMAND + YARN_RUN_SCRIPT_NAME,
          npm: [],
          capture_response: true
        )

        context.abort(
          context.message("features.argo.dependencies.yarn_run_script_error", error)
        ) unless status.success?
      end
    end
  end
end
