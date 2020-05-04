require 'shopify_cli'

module ShopifyCli
  module Commands
    Registry = CLI::Kit::CommandRegistry.new(
      default: 'help',
      contextual_resolver: nil,
    )
    @core_commands = []

    def self.register(const, cmd, path = nil)
      autoload(const, path) if path
      Registry.add(->() { const_get(const) }, cmd)
      @core_commands.push(cmd)
    end

    def self.core_command?(cmd)
      @core_commands.include?(cmd)
    end

    register :Connect, 'connect', 'shopify-cli/commands/connect'
    register :Create, 'create', 'shopify-cli/commands/create'
    register :Help, 'help', 'shopify-cli/commands/help'
    register :LoadDev, 'load-dev', 'shopify-cli/commands/load_dev'
    register :LoadSystem, 'load-system', 'shopify-cli/commands/load_system'
    register :Logout, 'logout', 'shopify-cli/commands/logout'
    register :System, 'system', 'shopify-cli/commands/system'
    register :Update, 'update', 'shopify-cli/commands/update'
  end
end
