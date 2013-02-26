module TreasureData
module Logger
module Agent::Rails

  class Config
    def assign_conf(conf)
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

      @test_mode = !!conf['test_mode']
      @access_log_table = conf['access_log_table']
    end

    attr_reader :agent_host, :agent_port, :tag
    attr_reader :apikey, :database, :auto_create_table
    attr_reader :access_log_table, :debug_mode, :test_mode
    attr_accessor :disabled

    def initialize
      @disabled = false
    end

    def agent_mode?
      @agent_host != nil
    end

    def test_mode?
      @test_mode
    end

    def access_log_enabled?
      !@access_log_table.nil? && !@access_log_table.empty?
    end

    def self.init
      c = Config.new
      config_path = CONFIG_PATH.start_with?('/') ? CONFIG_PATH : "#{::Rails.root}/#{CONFIG_PATH}"

      if File.exist?(config_path)
        c.load_file(config_path)
      elsif File.exist?(CONFIG_PATH_EY_DEPLOY)
        c.load_file_ey(CONFIG_PATH_EY_DEPLOY)
      elsif File.exist?(CONFIG_PATH_EY_LOCAL)
        c.load_file_ey(CONFIG_PATH_EY_LOCAL)
      else
        c.load_env
      end

      return c
    rescue
      warn "Disabling Treasure Data event logger: #{$!}"
      c.disabled = true
      return c
    end

    def load_file(path)
      conf = load_yaml(path)[::Rails.env]

      unless conf
        @disabled = true
        return
      end

      assign_conf(conf)
    end

    def load_file_ey(path)
      conf = load_yaml(path)
      apikey = conf['td']['TREASURE_DATA_API_KEY'] if conf.is_a?(Hash) and conf['td'].is_a?(Hash)

      unless apikey
        @disabled = true
        return
      end

      assign_conf({
        'apikey' => apikey,
        'database' => ENV['TREASURE_DATA_DB'] || "rails_#{::Rails.env}",
        'access_log_table' => ENV['TREASURE_DATA_ACCESS_LOG_TABLE'],
        'auto_create_table' => true
      })
    end

    def load_env
      apikey = ENV['TREASURE_DATA_API_KEY'] || ENV['TD_API_KEY']

      unless apikey
        @disabled = true
        return
      end

      assign_conf({
        'apikey' => apikey,
        'database' => ENV['TREASURE_DATA_DB'] || "rails_#{::Rails.env}",
        'access_log_table' => ENV['TREASURE_DATA_ACCESS_LOG_TABLE'],
        'auto_create_table' => true
      })
    end

    def load_yaml(path)
      require 'yaml'
      require 'erb'

      src = File.read(path)
      yaml = ERB.new(src).result
      YAML.load(yaml)
    end
  end

end
end
end
