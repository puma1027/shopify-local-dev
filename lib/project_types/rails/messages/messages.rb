# frozen_string_literal: true

module Rails
  module Messages
    MESSAGES = {
      rails: {
        error: {
          generic: "Error",
        },

        gem: {
          installed_debug: "%s installed: %s",
          installing: "Installing %s gem...",
          installed: "Installed %s gem",
        },

        create: {
          help: <<~HELP,
          {{command:%s create rails}}: Creates a ruby on rails app.
            Usage: {{command:%s create rails}}
            Options:
              {{command:--name=NAME}} App name. Any string.
              {{command:--app_url=APPURL}} App URL. Must be valid URL.
              {{command:--organization_id=ID}} App Org ID. Must be existing org ID.
              {{command:--shop_domain=MYSHOPIFYDOMAIN }} Test store URL. Must be existing test store.
              {{command:--db=DB}} Database type. Must be one of: mysql, postgresql, sqlite3, oracle, frontbase, ibm_db, sqlserver, jdbcmysql, jdbcsqlite3, jdbcpostgresql, jdbc.
              {{command:--rails_opts=RAILSOPTS}} Additional options. Must be string containing one or more valid Rails options, separated by spaces.
          HELP

          error: {
            invalid_ruby_version: <<~MSG,
            This project requires a ruby version ~> 2.4.
            See {{underline:https://github.com/Shopify/shopify-app-cli/blob/master/docs/installing-ruby.md}}
            for our recommended method of installing ruby.
            MSG
          },

          info: {
            created: "{{v}} {{green:%s}} was created in your Partner Dashboard {{underline:%s}}",
            serve: "{{*}} Run {{command:%s serve}} to start a local server",
            install: "{{*}} Then, visit {{underline:%s/test}} to install {{green:%s}} on your Dev Store",
          },
          installing_bundler: "Installing bundler…",
          generating_app: "Generating new rails app project in %s...",
          adding_shopify_gem: "{{v}} Adding shopify_app gem…",
          running_bundle_install: "Running bundle install...",
          running_generator: "Running shopify_app generator...",
          running_migrations: "Running migrations…",
        },

        deploy: {
          help: <<~HELP,
          Deploy the current Rails project to a hosting service. Heroku ({{underline:https://www.heroku.com}}) is currently the only option, but more will be added in the future.
            Usage: {{command:%s deploy [ heroku ]}}
          HELP
          extended_help: <<~HELP,
          {{bold:Subcommands:}}
            {{cyan:heroku}}: Deploys the current Rails project to Heroku.
              Usage: {{command:%s deploy heroku}}
          HELP

          heroku: {
            help: <<~HELP,
            Deploy the current Rails project to Heroku
            Usage: {{command:%s deploy heroku}}
            HELP
            downloading: "Downloading Heroku CLI…",
            downloaded: "Downloaded Heroku CLI",
            installing: "Installing Heroku CLI…",
            installed: "Installed Heroku CLI",
            authenticated_with_account: "{{v}} Authenticated with Heroku as `%s`",
            authenticating: "Authenticating with Heroku…",
            authenticated: "{{v}} Authenticated with Heroku",
            deploying: "Deploying to Heroku…",
            deployed: "{{v}} Deployed to Heroku",
            db_check: {
              validating: "Validating application...",
              checking: "Checking database type...",
              validated: "Database type \"%s\" validated for platform \"Heroku\"",
              problem: "A problem was encountered while checking your database type.",
              sqlite: "Heroku does not support deployment using SQLite database. Please change database using {{command:db:system:change --to=[new_db_type]}} ({{underline:https://gorails.com/episodes/rails-6-db-system-change-command}})",
            },
            git: {
              checking: "Checking git repo…",
              initialized: "Git repo initialized",
              what_branch: "What branch would you like to deploy?",
              branch_selected: "{{v}} Git branch `%s` selected for deploy",
            },
            app: {
              no_apps_found: "No existing Heroku app found. What would you like to do?",
              name: "What is your Heroku app’s name?",
              select: "Specify an existing Heroku app",
              selecting: "Selecting Heroku app `%s`…",
              selected: "{{v}} Heroku app `%s` selected",
              create: "Create a new Heroku app",
              creating: "Creating new Heroku app…",
              created: "{{v}} New Heroku app created",
            },
          },
        },

        generate: {
          help: <<~HELP,
          Generate code in your Rails project. Currently supports generating new webhooks.
            Usage: {{command:%s generate [ webhook ]}}
          HELP
          extended_help: <<~EXAMPLES,
          {{bold:Examples:}}
            {{cyan:%s generate webhook PRODUCTS_CREATE}}
              Generate and register a new webhook that will be called every time a new product is created on your store.
          EXAMPLES

          error: {
            name_exists: "%s already exists!",
            generic: "Error generating %s",
          },

          webhook: {
            help: <<~HELP,
            Generate and register a new webhook that listens for the specified Shopify store event.
              Usage: {{command:%s generate webhook <type>}}
            HELP

            select: "What type of webhook would you like to create?",
            selected: "Generating webhook: %s",
          },
        },

        open: {
          help: <<~HELP,
          Open your local development app in the default browser.
            Usage: {{command:%s open}}
          HELP
        },

        populate: {
          help: <<~HELP,
          Populate your Shopify development store with example customers, orders, or products.
            Usage: {{command:%s populate [ customers | draftorders | products ]}}
          HELP
          extended_help: <<~HELP,
          {{bold:Subcommands:}}

            {{cyan:customers [options]}}: Add dummy customers to the specified development store.
              Usage: {{command:%1$s populate customers}}

            {{cyan:draftorders [options]}}: Add dummy orders to the specified development store.
              Usage: {{command:%1$s populate draftorders}}

            {{cyan:products [options]}}: Add dummy products to the specified development store.
              Usage: {{command:%1$s populate products}}

          {{bold:Options:}}

            {{cyan:--count [integer]}}: The number of dummy items to populate. Defaults to 5.
            {{cyan:--silent}}: Silence the populate output.
            {{cyan:--help}}: Display more options specific to each subcommand.

          {{bold:Examples:}}

            {{command:%1$s populate products}}
              Populate your development store with 5 additional products.

            {{command:%1$s populate customers --count 30}}
              Populate your development store with 30 additional customers.

            {{command:%1$s populate draftorders}}
              Populate your development store with 5 additional orders.

            {{command:%1$s populate products --help}}
              Display the list of options available to customize the {{command:%1$s populate products}} command.
          HELP

          customer: {
            added: "%s added to {{green:%s}} at {{underline:%scustomers/%d}}",
          },

          draft_order: {
            added: "DraftOrder added to {{green:%s}} at {{underline:%sdraft_orders/%d}}",
          },

          product: {
            added: "%s added to {{green:%s}} at {{underline:%sproducts/%d}}",
          },
        },

        serve: {
          help: <<~HELP,
          Start a local development rails server for your project, as well as a public ngrok tunnel to your localhost.
            Usage: {{command:%s serve}}
          HELP
          extended_help: <<~HELP,
          {{bold:Options:}}
            {{cyan:--host=HOST}}: Bypass running tunnel and use custom host. HOST must be HTTPS url.
          HELP

          error: {
            host_must_be_https: "{{red:HOST must be a HTTPS url.}}",
          },

          open_info: "{{*}} Press {{yellow: Control-T}} to open this project in {{green:%s}} ",
          running_server: "Running server...",
        },

        tunnel: {
          help: <<~HELP,
          Start or stop an http tunnel to your local development app using ngrok.
            Usage: {{command:%s tunnel [ auth | start | stop ]}}
          HELP
          extended_help: <<~HELP,
          {{bold:Subcommands:}}

            {{cyan:auth}}: Writes an ngrok auth token to ~/.ngrok2/ngrok.yml to connect with an ngrok account. Visit https://dashboard.ngrok.com/signup to sign up.
              Usage: {{command:%1$s tunnel auth <token>}}

            {{cyan:start}}: Starts an ngrok tunnel, will print the URL for an existing tunnel if already running.
              Usage: {{command:%1$s tunnel start}}

            {{cyan:stop}}: Stops the ngrok tunnel.
              Usage: {{command:%1$s tunnel stop}}

          HELP

          error: {
            token_argument_missing: "{{x}} {{red:auth requires a token argument}}\n\n",
          },
        },

        forms: {
          create: {
            error: {
              invalid_app_type: "Invalid App Type %s",
              invalid_db_type: "Invalid DB Type %s",
              organization_not_found: "Cannot find an organization with that ID",
              no_organizations: "No organizations available.",
            },

            authentication_issue: "For authentication issues, run {{command:%s logout}} to clear invalid credentials",
            partners_notice: "Please visit https://partners.shopify.com/ to create a partners account",
            no_development_stores: "{{x}} No Development Stores available.",
            create_store: "Visit {{underline:https://partners.shopify.com/%s/stores}} to create one",
            app_name: "App Name",
            app_type: {
              select: "What type of app are you building?",
              select_public: "Public: An app built for a wide merchant audience.",
              select_custom: "Custom: An app custom built for a single client.",
              selected: "App Type {{green:%s}}",
            },
            db: {
              want_select: {
                select: "Would you like to select your database now? If you want to change this in the future, run {{command:db:system:change --to=[new_db_type]}} ({{underline:https://gorails.com/episodes/rails-6-db-system-change-command}})",
                select_no: "No",
                select_yes: "Yes",
              },
              type: {
                select: "What database type would you like to use? Please ensure the database is installed.",
                select_sqlite: "SQLite (default)",
                select_mysql: "MySQL",
                select_pg: "PostgreSQL",
                select_oracle: "Oracle",
                select_fb: "FrontBase",
                select_ibm: "IBM_DB",
                select_sql: "SQL Server",
                select_jdbc_mysql: "JDBC MySQL",
                select_jdbc_sqlite: "JDBC SQlite3",
                select_jdbc_pg: "JDBC PostgreSQL",
                select_jdbc: "JDBC",
                selected: "Database Type {{green:%s}}",
              },
            },
            organization_select: "Select organization",
            organization: "Organization {{green:%s}}",
            development_store_select: "Select a Development Store",
            development_store: "Using Development Store {{green:%s}}",
          },
        },
      },
    }.freeze
  end
end
