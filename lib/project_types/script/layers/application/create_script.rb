# frozen_string_literal: true

require "shopify_cli"

module Script
  module Layers
    module Application
      class CreateScript
        class << self
          def call(ctx:, language:, branch:, script_name:, extension_point_type:, no_config_ui:)
            raise Infrastructure::Errors::ScriptProjectAlreadyExistsError, script_name if ctx.dir_exist?(script_name)

            in_new_directory_context(ctx, script_name) do
              extension_point = ExtensionPoints.get(type: extension_point_type)
              script_project_repo = Infrastructure::ScriptProjectRepository.new(ctx: ctx)
              project = script_project_repo.create(
                script_name: script_name,
                extension_point_type: extension_point_type,
                language: language
              )

              # remove the need to pass the whole extension-point object to the infra layer
              repo = extension_point.sdks.for(language).repo
              type = extension_point.dasherize_type
              domain = extension_point.domain

              sparse_checkout_set_path = "packages/#{domain}/samples/#{type}"
              if domain.nil?
                sparse_checkout_set_path = "packages/default/extension-point-as-#{type}/assembly/sample"
              end

              project_creator = Infrastructure::Languages::ProjectCreator.for(
                ctx: ctx,
                language: language,
                domain: domain,
                type: type,
                repo: repo,
                project_name: script_name,
                path_to_project: project.id,
                branch: branch,
                sparse_checkout_set_path: sparse_checkout_set_path
              )

              install_dependencies(ctx, language, script_name, project_creator)
              script_project_repo.update_or_create_script_json(title: script_name, configuration_ui: !no_config_ui)
              project
            end
          end

          private

          def install_dependencies(ctx, language, script_name, project_creator)
            task_runner = Infrastructure::Languages::TaskRunner.for(ctx, language, script_name)
            CLI::UI::Frame.open(ctx.message(
              "core.git.pulling_from_to",
              project_creator.repo,
              script_name,
            )) do
              UI::StrictSpinner.spin(ctx.message(
                "core.git.pulling",
                project_creator.repo,
                script_name,
              )) do |spinner|
                project_creator.setup_dependencies
                spinner.update_title(ctx.message("core.git.pulled", script_name))
              end
            end
            ProjectDependencies.install(ctx: ctx, task_runner: task_runner)
          end

          def in_new_directory_context(ctx, directory)
            initial_directory = ctx.root
            begin
              ctx.mkdir_p(directory)
              ctx.chdir(directory)
              yield
            rescue
              ctx.chdir(initial_directory)
              ctx.rm_r(directory)
              raise
            ensure
              ctx.chdir(initial_directory)
            end
          end
        end
      end
    end
  end
end
