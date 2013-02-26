require 'fluent/logger'

module TreasureData
module Logger
  autoload :TreasureDataLogger, 'td/logger/td_logger'

  @@logger = nil

  def self.logger
    @@logger
  end

  def self.open(database, options={})
    @@logger = TreasureData::Logger::TreasureDataLogger.new(database, options)
  end

  def self.open_agent(tag, options={})
    @@logger = Fluent::Logger::FluentLogger.new(tag, options)
  end

  def self.open_null
    @@logger = Fluent::Logger::NullLogger.new
  end

  def self.open_test
    @@logger = Fluent::Logger::TestLogger.new
  end

  def self.post(tag, record={})
    @@logger.post(tag, record)
  end

  def self.post_with_time(tag, record, time)
    @@logger.post_with_time(tag, record, time)
  end
end
end


# shortcut methods
module TreasureData
  require 'td/logger/event'

  def self.logger
    TreasureData::Logger.logger
  end

  def self.open(database, options={})
    TreasureData::Logger.open(database, options)
  end

  def self.open_agent(tag, options={})
    TreasureData::Logger.open_agent(tag, options)
  end

  def self.open_null
    TreasureData::Logger.open_null
  end

  def self.open_test
    TreasureData::Logger.open_test
  end

  def self.post(tag, record={})
    TreasureData::Logger.post(tag, record)
  end

  def self.post_with_time(tag, record, time)
    TreasureData::Logger.post_with_time(tag, record, time)
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

