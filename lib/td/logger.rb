require 'fluent/logger'

module TreasureData
module Logger
  autoload :TreasureDataLogger, 'td/logger/td_logger'

  @@logger = nil

  def self.open(database, options={})
    @@logger = TreasureData::Logger::TreasureDataLogger.new(database, options)
  end

  def self.open_agent(tag, options={})
    @@logger = Fluent::Logger::FluentLogger.new(tag, options)
  end

  def self.open_null
    @@logger = Fluent::Logger::NullLogger.new
  end

  def self.post(tag, record={}, time=nil)
    @@logger.post(tag, record={}, time)
  end
end
end


# shortcut methods
module TreasureData
  require 'td/logger/event'

  def self.open(database, options={})
    TreasureData::Logger.open(database, options)
  end

  def self.open_agent(tag, options={})
    TreasureData::Logger.open_agent(tag, options)
  end

  def self.open_null
    TreasureData::Logger.open_null
  end

  def self.post(tag, record={}, time=nil)
    TreasureData::Logger.post(tag, record, time)
  end

  def self.event
    TreasureData::Logger.event
  end

  Event = TreasureData::Logger::Event

  # backward compatibility
  def self.log(*args)  # :nodoc:
    TreasureData::Logger.post(*args)
  end
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

