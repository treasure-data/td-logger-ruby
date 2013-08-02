module TreasureData
module Logger
module Agent::Rails

  CONFIG_PATH = ENV['TREASURE_DATA_YML'] || 'config/treasure_data.yml'
  CONFIG_PATH_EY_LOCAL = "#{::Rails.root}/config/ey_services_config_local.yml"
  CONFIG_PATH_EY_DEPLOY = "#{::Rails.root}/config/ey_services_config_deploy.yml"

  require 'td/logger/agent/rack'
  require 'td/logger/agent/rails/config'
  require 'td/logger/agent/rails/controller'
  #require 'td/logger/agent/rails/model'

  def self.init(rails)
    c = Config.init
    if c.disabled
      warn 'Disabling Treasure Data event logger.'
      ::TreasureData::Logger.open_null
      return false
    end

    if c.test_mode?
      ::TreasureData::Logger.open_test
    elsif c.agent_mode?
      ::TreasureData::Logger.open_agent(c.tag, :host=>c.agent_host, :port=>c.agent_port, :debug=>c.debug_mode)
    else
      ::TreasureData::Logger.open(c.database, :apikey=>c.apikey, :auto_create_table=>c.auto_create_table, :debug=>c.debug_mode)
    end

    rails.middleware.use Agent::Rack::Hook

    Agent::Rack::Hook.before do |env|
      TreasureData::Logger.event.attribute.clear
    end

    Agent::Rails::ControllerExtension.init
    #Agent::Rails::AccessLogger.init(c.access_log_table) if c.access_log_enabled?
    #Agent::Rails::ModelExtension.init

    true
  end

  if ::Rails.respond_to?(:version) && ::Rails.version.to_i >= 3
    class Railtie < ::Rails::Railtie
      initializer "treasure_data_logger.start_plugin" do |app|
        TreasureData::Logger::Agent::Rails.init(app.config)
      end
    end
  else
    TreasureData::Logger::Agent::Rails.init(::Rails.configuration)
  end

  # implement ActiveSupport::TimeWithZone#to_msgpack
  unless ActiveSupport::TimeWithZone.method_defined?(:to_msgpack)
    class ActiveSupport::TimeWithZone
      def to_msgpack(out='')
        strftime("%Y-%m-%d %H:%M:%S %z").to_msgpack(out)
      end
    end
  end
end
end
end
