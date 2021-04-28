# frozen_string_literal: true
module Theme
  class Project < ShopifyCli::ProjectType
    require Project.project_filepath("messages/messages")
    register_messages(Theme::Messages::MESSAGES)
  end

  class Command < ShopifyCli::ProjectCommands
    subcommand :Init, "init", Project.project_filepath("commands/init")
    subcommand :Connect, "connect", Project.project_filepath("commands/connect")
    subcommand :Publish, "publish", Project.project_filepath("commands/publish")
    subcommand :Push, "push", Project.project_filepath("commands/push")
    subcommand :Serve, "serve", Project.project_filepath("commands/serve")
    subcommand :Check, "check", Project.project_filepath("commands/check")
    subcommand :Delete, "delete", Project.project_filepath("commands/delete")
  end
  ShopifyCli::Commands.register("Theme::Command", "theme")

  module Forms
    autoload :Connect, Project.project_filepath("forms/connect")
    autoload :Select, Project.project_filepath("forms/select")
  end
end
