require 'fluent/logger'

module TreasureData

def self.open(apikey, database, auto_create_table=false)
  require 'td/logger/tdlog'
  TreasureDataLogger.open(apikey, database, auto_create_table)
end

def self.open_agent(tag, agent_host, agent_port)
  Fluent::Logger::FluentLogger.open(tag, agent_host, agent_port)
end

def self.log(tag, record)
  record['time'] ||= Time.now.to_i
  Fluent::Logger.post(tag, record)
end

end


class Time
  def to_msgpack(out = '')
    to_i.to_msgpack(out)
  end
end


if defined? Rails
  require 'td/logger/agent/rails'
end

