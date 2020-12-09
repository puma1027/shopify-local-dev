module ShopifyCli
  ##
  # ShopifyCli::Feature contains the logic to hide and show features across the CLI
  # These features can be either commands or project types currently.
  #
  # Feature flags will persist between runs so if the flag is enabled or disabled,
  # it will still be in that same state on the next cli invocation.
  class Feature
    SECTION = 'features'

    ##
    # ShopifyCli::Feature::Set is included on commands and projects to allow you to hide
    # and enable projects and commands based on feature flags.
    module Set
      ##
      # will hide a feature, either a project_type or a command
      #
      # #### Parameters
      #
      # * `feature_set` - either a single, or array of symbols that represent feature sets
      #
      # #### Example
      #
      #    module ShopifyCli
      #      module Commands
      #        class Config < ShopifyCli::Command
      #          hidden_feature(feature_set: :basic)
      #          ....
      #
      def hidden_feature(feature_set: [])
        @feature_hidden = true
        @hidden_feature_set = Array(feature_set).compact
      end

      ##
      # will return if the feature has been hidden or not
      #
      # #### Returns
      #
      # * `is_hidden` - returns true if the feature has been hidden and false otherwise
      #
      # #### Example
      #
      #     ShopifyCli::Commands::Config.hidden?
      #
      def hidden?
        enabled = (@hidden_feature_set || []).any? { |feature| Feature.enabled?(feature) }
        @feature_hidden && !enabled
      end
    end

    class << self
      ##
      # will enable a feature in the CLI.
      #
      # #### Parameters
      #
      # * `feature` - a symbol representing the flag to be enabled
      def enable(feature)
        set(feature, true)
      end

      ##
      # will disable a feature in the CLI.
      #
      # #### Parameters
      #
      # * `feature` - a symbol representing the flag to be disabled
      def disable(feature)
        set(feature, false)
      end

      ##
      # will check if the feature has been enabled
      #
      # #### Parameters
      #
      # * `feature` - a symbol representing a flag that the status should be requested
      #
      # #### Returns
      #
      # * `is_enabled` - will be true if the feature has been enabled.
      def enabled?(feature)
        return false if feature.nil?
        ShopifyCli::Config.get_bool(SECTION, feature.to_s)
      end

      private

      def set(feature, value)
        ShopifyCli::Config.set(SECTION, feature.to_s, value)
      end
    end
  end
end
