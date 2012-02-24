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

        @debug_mode = !!conf['debug_mode']
      end

      @access_log_table = conf['access_log_table']
    end

    attr_reader :agent_host, :agent_port, :tag
    attr_reader :apikey, :database, :auto_create_table
    attr_reader :access_log_table, :debug_mode

    def agent_mode?
      @agent_host != nil
    end

    def access_log_enabled?
      !@access_log_table.nil? && !@access_log_table.empty?
    end

    def self.init
      logger = ::Logger.new(STDERR)
      if File.exist?("#{::Rails.root}/#{CONFIG_PATH}")
        load_file(logger)
      else
        if File.exist?("#{::Rails.root}/#{CONFIG_PATH_EY_DEPLOY}")
          load_file_ey(logger, "#{::Rails.root}/#{CONFIG_PATH_EY_DEPLOY}")
        elsif File.exist?("#{::Rails.root}/#{CONFIG_PATH_EY_LOCAL}")
          load_file_ey(logger, "#{::Rails.root}/#{CONFIG_PATH_EY_LOCAL}")
        else
          load_env(logger)
        end
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
        logger.warn "WARNING: Can't load #{CONFIG_PATH} file: #{$!}"
        logger.warn "WARNING: Disabling Treasure Data event logger."
        return nil
      end

      conf = env_conf[::Rails.env] if env_conf.is_a?(Hash)
      unless conf
        logger.warn "WARNING: #{CONFIG_PATH} doesn't include setting for current environment (#{::Rails.env})."
        logger.warn "WARNING: Disabling Treasure Data event logger."
        return nil
      end

      begin
        return Config.new(conf)
      rescue
        logger.warn "WARNING: #{CONFIG_PATH}: #{$!}."
        logger.warn "WARNING: Disabling Treasure Data event logger."
        return nil
      end
    end

    def self.load_file_ey(logger, path)
      require 'yaml'
      require 'erb'

      begin
        src = File.read(path)
        yaml = ERB.new(src).result
        env_conf = YAML.load(yaml)
      rescue
        logger.warn "WARNING: Can't load #{path} file: #{$!}"
        logger.warn "WARNING: Disabling Treasure Data event logger."
        return nil
      end

      apikey = env_conf['td']['TREASURE_DATA_API_KEY'] if env_conf.is_a?(Hash) and env_conf['td'].is_a?(Hash)
      unless apikey
        logger.warn "WARNING: #{path} does not have a configuration of API key."
        logger.warn "WARNING: Disabling Treasure Data event logger."
        return nil
      end

      return Config.new({
        'apikey' => apikey,
        'database' => ENV['TREASURE_DATA_DB'] || "rails_#{::Rails.env}",
        'access_log_table' => ENV['TREASURE_DATA_ACCESS_LOG_TABLE'],
        'auto_create_table' => true
      })
    end

    def self.load_env(logger)
      apikey = ENV['TREASURE_DATA_API_KEY'] || ENV['TD_API_KEY']

      unless apikey
        logger.warn "WARNING: #{CONFIG_PATH} does not exist."
        logger.warn "WARNING: Disabling Treasure Data event logger."
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
