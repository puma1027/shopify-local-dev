# frozen_string_literal: true
require "shopify_cli"

module Extension
  module Commands
    class ExtensionCommand < ShopifyCli::Command
      def project
        @project ||= ExtensionProject.current
      end

      def specification
        specification_handler.specification
      end

      def specification_handler
        @specification_handler ||= begin
          identifier = project.specification_identifier
          Models::LazySpecificationHandler.new(identifier) do
            specifications = Models::Specifications.new(
              fetch_specifications: Tasks::FetchSpecifications.new(api_key: project.app.api_key, context: @ctx)
            )

            unless specifications.valid?(identifier)
              @ctx.abort(@ctx.message("errors.unknown_type", project.specification_identifier))
            end

            specifications[identifier]
          end
        end
      end
    end
  end
end
