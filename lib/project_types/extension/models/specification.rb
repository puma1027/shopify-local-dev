module Extension
  module Models
    class Specification
      include SmartProperties

      module Features
        class Argo
          include SmartProperties

          property! :surface, converts: :to_str
          property! :renderer_package_name, converts: :to_str
          property! :git_template, converts: :to_str
        end

        def self.build(feature_set_attributes)
          feature_set_attributes.each_with_object(OpenStruct.new) do |(identifier, feature_attributes), feature_set|
            feature_set[identifier] = ShopifyCli::ResolveConstant
              .call(identifier, namespace: Features)
              .rescue { OpenStruct }
              .then { |c| c.new(**feature_attributes) }
              .unwrap { |error| raise(error) }
          end
        end
      end

      property! :identifier
      property :name, converts: :to_str
      property :graphql_identifier, converts: :to_str
      property! :features, converts: Features.method(:build), default: -> { [] }
      property! :options, converts: ->(options) { OpenStruct.new(options) }, default: -> { OpenStruct.new }

      def graphql_identifier
        super || identifier
      end
    end
  end
end
