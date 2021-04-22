module Theme
  module Forms
    class Select < ShopifyCli::Form
      attr_accessor :theme
      flag_arguments :config, :title

      def ask
        self.theme = CLI::UI::Prompt.ask(title, allow_empty: false) do |handler|
          ShopifyCli::Theme::Theme.all(@ctx, config).each do |theme|
            handler.option("#{theme.name} {{green:[#{theme.role}]}}") { theme }
          end
        end
      end
    end
  end
end
