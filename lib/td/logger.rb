
module TreasureData
module Logger


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
  end

  attr_reader :agent_host, :agent_port, :tag
  attr_reader :apikey, :database, :auto_create_table

  def agent_mode?
    @agent_host != nil
  end
end


end
end


module TreasureData


def self.log(tag, record)
  record['time'] ||= Time.now.to_i
  Fluent::Logger.post(tag, record)
end


module Logger
module RailsAgent

CONFIG_SAMPLE = <<EOF
defaults: &defaults
  apikey: "YOUR_API_KEY"
  database: myapp
  table: access

test:
  <<: *defaults

development:
  <<: *defaults

production:
  <<: *defaults
EOF

CONFIG_PATH = 'config/treasure_data.yml'

def self.init(rails)
  c = read_config(rails)
  return unless c

  require 'fluent/logger'
  if c.agent_mode?
    Fluent::Logger::FluentLogger.open(c.tag, c.agent_host, c.agent_port)
  else
    require 'td/logger/tdlog'
    TreasureDataLogger.open(c.apikey, c.database, c.auto_create_table)
  end

  rails.middleware.use Middleware
  ActionController::Base.class_eval do
    include ::TreasureData::Logger::RailsAgent::ControllerLogger
  end
end

def self.read_config(rails)
  logger = Rails.logger || ::Logger.new(STDOUT)
  begin
    yaml = YAML.load_file("#{RAILS_ROOT}/#{CONFIG_PATH}")
  rescue
    logger.warn "Can't load #{CONFIG_PATH} file."
    logger.warn "  #{$!}"
    logger.warn "Put the following file:"
    logger.warn sample
    return
  end

  conf = yaml[RAILS_ENV]
  unless conf
    logger.warn "#{CONFIG_PATH} doesn't include setting for current environment (#{RAILS_ENV})."
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

class Middleware
  def initialize(app, options={})
    @app = app
  end

  def call(env)
    r = @app.call(env)

    if m = env['treasure_data.log_method']
      m.call(env)
    end

    r
  end

  def self.set_log_method(env, method)
    env['treasure_data.log_method'] = method
  end
end

module ControllerLogger
  def self.included(mod)
    mod.extend(ModuleMethods)
  end

  class ActionLogger
    PARAM_KEY = if defined? Rails
        if Rails.respond_to?(:version) && Rails.version =~ /^3/
          # Rails 3
          'action_dispatch.request.path_parameters'
        else
          # Rails 2
          'action_controller.request.path_parameters'
        end
      else
        # Rack default
        'rack.routing_args'
      end

    def initialize(method, tag, options)
      @method = method
      @tag = tag

      @only = nil
      @except = nil
      @extra = nil
      @static = {}

      if o = options[:only_params]
        @only = case o
          when Array
            o
          else
            [o]
          end.map {|e| e.to_s }
      end

      if o = options[:except_params]
        @except = case o
          when Array
            o
          else
            [o]
          end.map {|e| e.to_s }
      end

      if o = options[:extra]
        @extra = case o
          when Hash
            m = {}
            o.each_pair {|k,v| m[k.to_s] = v.to_s }
            m
          when Array
            o.map {|e|
              case e
              when Hash
                m = {}
                e.each_pair {|k,v| m[k.to_s] = v.to_s }
                m
              else
                {e.to_s => e.to_s}
              end
            }.inject({}) {|r,e| r.merge!(e) }
          else
            {o.to_s => o.to_s}
          end
      end

      if o = options[:static]
        o.each_pair {|k,v| @static[k] = v }
      end
    end

    def call(env)
      m = env[PARAM_KEY].dup || {}

      if @only
        m.reject! {|k,v| !@only.include?(k) }
      end
      if @except
        m.reject! {|k,v| @except.include?(k) }
      end
      if @extra
        @extra.each_pair {|k,v| m[v] = env[k] }
      end

      m.merge!(@static)

      ::TreasureData.log(@tag, m)
    end
  end

  module ModuleMethods
    def add_td_tracer(method, tag, options={})
      al = ActionLogger.new(method, tag, options)
      module_eval <<-EOF
        def #{method}_td_action_tracer_(*args, &block)
          ::TreasureData::Logger::RailsAgent::Middleware.set_log_method(request.env, method(:#{method}_td_action_trace_))
          #{method}_td_action_tracer_orig_(*args, &block)
        end
      EOF
      module_eval do
        define_method(:"#{method}_td_action_trace_", &al.method(:call))
      end
      alias_method "#{method}_td_action_tracer_orig_", method
      alias_method method, "#{method}_td_action_tracer_"
    end
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
          TreasureData::Logger::RailsAgent.init(app.config)
        end
      end
    end
  else
    TreasureData::Logger::RailsAgent.init(Rails.configuration)
  end
end

