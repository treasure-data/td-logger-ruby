module TreasureData
module Logger
module Agent
  require 'td/logger/agent/middleware'
  require 'td/logger/agent/access_log'
  require 'td/logger/agent/rails/controller'
  require 'td/logger/agent/rails/model'

  module Rails

    CONFIG_PATH = 'config/treasure_data.yml'

    CONFIG_SAMPLE = <<EOF
# logging to Treasure Data directly
development:
  apikey: "YOUR_API_KEY"
  database: myapp
  access_log_table: access
  auto_create_table: true

# logging via td-agent
production:
  agent: "localhost:24224"
  tag: td.myapp
  access_log_table: access

# disable logging
test:
EOF

    def self.rails_env
      if defined?(RAILS_ENV) && RAILS_ENV.to_s != ''
        RAILS_ENV.to_s
      else
        ::Rails.env
      end
    end
    
    def self.rails_root
      if defined?(RAILS_ROOT) && RAILS_ROOT.to_s != ''
        RAILS_ROOT.to_s
      else
        ::Rails.root
      end
    end

    class Config
      def initialize(conf)
        if agent = conf['agent']
          host, port = agent.split(':',2)
          port = (port || 24224).to_i
          @agent_host = host
          @agent_port = port

          @tag = conf['tag']
          @tag ||= conf['database']
          raise "'tag' nor 'database' options are not set" unless @tag

        else
          @apikey = conf['apikey']
          raise "'apikey' option is not set" unless @apikey

          @database = conf['database']
          raise "'database' option is not set" unless @database

          @auto_create_table = !!conf['auto_create_table']
        end

        @access_log_table = conf['access_log_table']
      end

      attr_reader :agent_host, :agent_port, :tag
      attr_reader :apikey, :database, :auto_create_table
      attr_reader :access_log_table

      def agent_mode?
        @agent_host != nil
      end

      def access_log_enabled?
        !@access_log_table.nil? && !@access_log_table.empty?
      end
    end

    def self.read_config(rails)
      require 'yaml'
      require 'erb'
      logger = ::Rails.logger || ::Logger.new(STDOUT)
      begin
        src = File.read("#{rails_root}/#{CONFIG_PATH}")
        yaml = ERB.new(src).result
        env_conf = YAML.load(yaml)
      rescue
        logger.warn "Can't load #{CONFIG_PATH} file."
        logger.warn "  #{$!}"
        logger.warn "Put the following file:"
        logger.warn CONFIG_SAMPLE
        return
      end

      conf = env_conf[rails_env]
      unless conf
        logger.warn "#{CONFIG_PATH} doesn't include setting for current environment (#{rails_env})."
        logger.warn "Disabling Treasure Data logger."
        return
      end

      begin
        return Config.new(conf)
      rescue
        logger.warn "#{CONFIG_PATH}: #{$!}."
        logger.warn "Disabling Treasure Data logger."
        return
      end
    end

    def self.init(rails)
      c = read_config(rails)
      return unless c

      if c.agent_mode?
        ::TreasureData.open_agent(c.tag, c.agent_host, c.agent_port)
      else
        ::TreasureData.open(c.apikey, c.database, c.auto_create_table)
      end

      rails.middleware.use Agent::Middleware

      if c.access_log_enabled?
        Agent.enable_access_log(c.access_log_table)
      end
      Agent::Rails.init_controller
      Agent::Rails.init_model
    end

  end
end
end
end

if defined? Rails
  if Rails.respond_to?(:version) && Rails.version =~ /^3/
    module TreasureData
      class Railtie < Rails::Railtie
        initializer "treasure_data_agent.start_plugin" do |app|
          TreasureData::Logger::Agent::Rails.init(app.config)
        end
      end
    end
  else
    TreasureData::Logger::Agent::Rails.init(Rails.configuration)
  end
end

