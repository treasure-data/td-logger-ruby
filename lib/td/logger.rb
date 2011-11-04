require 'fluent/logger'

module TreasureData
module Logger
  autoload :TreasureDataLogger, 'td/logger/td_logger'

  def self.open(apikey, database, auto_create_table=false)
    TreasureData::Logger::TreasureDataLogger.open(apikey, database, auto_create_table)
  end

  def self.open_agent(tag, agent_host, agent_port)
    Fluent::Logger::FluentLogger.open(tag, agent_host, agent_port)
  end

  def self.post(tag, record, time=nil)
    Fluent::Logger.post(tag, record, time)
  end
end
end


# shortcut methods
module TreasureData
  def self.open(apikey, database, auto_create_table=false)
    TreasureData::Logger.open(apikey, database, auto_create_table=false)
  end

  def self.open_agent(tag, agent_host, agent_port)
    TreasureData::Logger.open_agent(tag, agent_host, agent_port)
  end

  def self.post(tag, record, time=nil)
    TreasureData::Logger.post(tag, record, time)
  end

  def self.event
    TreasureData::Logger.event
  end

  # backward compatibility
  def self.log(*args)  # :nodoc:
    TreasureData::Logger.post(*args)
  end

  require 'td/logger/event'
  Event = TreasureData::Logger::Event
end

# shortcut constants
TD = TreasureData

if defined? ::Rails
  require 'td/logger/agent/rails'
end

