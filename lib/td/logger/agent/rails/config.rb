module TreasureData
module Logger
module Agent::Rails

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

        if conf.has_key?('auto_create_table')
          @auto_create_table = !!conf['auto_create_table']
        else
          @auto_create_table = true
        end
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

    def self.init
      logger = ::Rails.logger || ::Logger.new(STDERR)
      if File.exist?("#{::Rails.root}/#{CONFIG_PATH}")
        load_file(logger)
      else
        load_env(logger)
      end
    end

    def self.load_file(logger)
      require 'yaml'
      require 'erb'

      begin
        src = File.read("#{::Rails.root}/#{CONFIG_PATH}")
        yaml = ERB.new(src).result
        env_conf = YAML.load(yaml)
      rescue
        logger.warn "Can't load #{CONFIG_PATH} file: #{$!}"
        logger.warn "Disabling Treasure Data logger."
        return nil
      end

      conf = env_conf[::Rails.env]
      unless conf
        logger.warn "#{CONFIG_PATH} doesn't include setting for current environment (#{::Rails.env})."
        logger.warn "Disabling Treasure Data logger."
        return nil
      end

      begin
        return Config.new(conf)
      rescue
        logger.warn "#{CONFIG_PATH}: #{$!}."
        logger.warn "Disabling Treasure Data logger."
        return nil
      end
    end

    def self.load_env(logger)
      apikey = ENV['TREASURE_DATA_API_KEY'] || ENV['TD_API_KEY']

      unless apikey
        logger.warn "#{CONFIG_PATH} does not exist."
        logger.warn "Disabling Treasure Data logger."
        return nil
      end

      return Config.new({
        'apikey' => apikey,
        'database' => ENV['TREASURE_DATA_DB'] || "rails_#{::Rails.env}",
        'access_log_table' => ENV['TREASURE_DATA_ACCESS_LOG_TABLE'],
        'auto_create_table' => true
      })
    end
  end

end
end
end
