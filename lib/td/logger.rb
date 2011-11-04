require 'fluent/logger'

module TreasureData
module Logger
  autoload :TreasureDataLogger, 'td/logger/td_logger'

  def self.open(database, options={})
    TreasureData::Logger::TreasureDataLogger.open(database, options)
  end

  def self.open_agent(tag, options={})
    Fluent::Logger::FluentLogger.open(tag, options)
  end

  def self.post(tag, record, time=nil)
    Fluent::Logger.post(tag, record, time)
  end
end
end


# shortcut methods
module TreasureData
  def self.open(database, options={})
    TreasureData::Logger.open(database, options)
  end

  def self.open_agent(tag, options={})
    TreasureData::Logger.open_agent(tag, options)
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

# implement Time#to_msgpack
unless Time.now.respond_to?(:to_msgpack)
  class Time
    def to_msgpack(out='')
      strftime("%Y-%m-%d %H:%M:%S %z").to_msgpack(out)
    end
  end
end

module TreasureData::Logger::Agent
  if defined? ::Rails
    require 'td/logger/agent/rails'
  end
end

