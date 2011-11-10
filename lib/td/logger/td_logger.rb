module TreasureData
module Logger


class TreasureDataLogger < Fluent::Logger::LoggerBase
  module Finalizable
    require 'delegate'
    def new(*args, &block)
      obj = allocate
      obj.instance_eval { initialize(*args, &block) }
      dc = DelegateClass(obj.class).new(obj)
      ObjectSpace.define_finalizer(dc, finalizer(obj))
      dc
    end

    def finalizer(obj)
      fin = obj.method(:finalize)
      proc {|id|
        fin.call
      }
    end
  end
  extend Finalizable

  def initialize(tag_prefix, options={})
    defaults = {
      :auto_create_table => false,
    }
    options = defaults.merge!(options)

    @tag_prefix = tag_prefix
    @auto_create_table = !!options[:auto_create_table]

    apikey = options[:apikey]
    unless apikey
      raise ArgumentError, ":apikey options is required"
    end

    debug = !!options[:debug]

    require 'thread'
    require 'stringio'
    require 'zlib'
    require 'msgpack'
    require 'json'
    require 'time'
    require 'net/http'
    require 'cgi'
    require 'logger'
    require 'td-client'

    @logger = ::Logger.new(STDERR)
    if debug
      @logger.level = ::Logger::DEBUG
    else
      @logger.level = ::Logger::INFO
    end

    @client = TreasureData::Client.new(apikey)

    @mutex = Mutex.new
    @cond = ConditionVariable.new
    @map = {}  # (db,table) => buffer:String
    @queue = []

    @chunk_limit = 8*1024*1024
    @flush_interval = 10
    @max_flush_interval = 300
    @retry_wait = 1.0
    @retry_limit = 8

    @finish = false
    @next_time = Time.now.to_i + @flush_interval
    @error_count = 0

    # start thread when the first post() is called for
    # Unicorn and Passenger.
    @upload_thread = nil
  end

  attr_accessor :logger

  def close
    unless @finish
      @finish = true
      @mutex.synchronize {
        @flush_now = true
        @cond.signal
      }
      @upload_thread.join if @upload_thread

      @map.each {|(db,table),buffer|
        upload(db, table, buffer)
      }
      @queue.each {|tuple|
        upload(*tuple)
      }
    end
  end

  def post_with_time(tag, record, time)
    @logger.debug { "event: #{tag} #{record.to_json}" rescue nil }

    record[:time] ||= time.to_i

    tag = "#{@tag_prefix}.#{tag}" if @tag_prefix
    db, table = tag.split('.')[-2, 2]

    add(db, table, record)
  end

  def upload_main
    @mutex.lock
    until @finish
      now = Time.now.to_i

      if @next_time <= now || (@flush_now && @error_count == 0)
        @mutex.unlock
        begin
          flushed = try_flush
        ensure
          @mutex.lock
        end
        @flush_now = false
      end

      if @error_count == 0
        if flushed && @flush_interval < @max_flush_interval
          @flush_interval = [@flush_interval + 60, @max_flush_interval].min
        end
        next_wait = @flush_interval
      else
        next_wait = @retry_wait * (2 ** (@error_count-1))
      end
      @next_time = next_wait + now

      cond_wait(next_wait)
    end

  rescue
    @logger.error "Unexpected error: #{$!}"
    $!.backtrace.each {|bt|
      @logger.info bt
    }
  ensure
    @mutex.unlock
  end

  private
  def to_msgpack(msg)
    begin
      msg.to_msgpack
    rescue NoMethodError
      JSON.load(JSON.dump(msg)).to_msgpack
    end
  end

  def add(db, table, msg)
    begin
      TreasureData::API.validate_database_name(db)
    rescue
      @logger.error("TreasureDataLogger: Invalid database name #{db.inspect}: #{$!}")
      return false
    end
    begin
      TreasureData::API.validate_table_name(table)
      @logger.error("TreasureDataLogger: Invalid table name #{table.inspect}: #{$!}")
    rescue
      return false
    end

    begin
      data = to_msgpack(msg)
    rescue
      @logger.error("TreasureDataLogger: Can't convert to msgpack: #{msg.inspect}: #{$!}")
      return false
    end

    key = [db, table]

    @mutex.synchronize do
      buffer = (@map[key] ||= '')

      buffer << data

      if buffer.size > @chunk_limit
        @queue << [db, table, buffer]
        @map.delete(key)
        @cond.signal
      end

      # stat upload thread if it's not run
      unless @upload_thread
        @upload_thread = Thread.new(&method(:upload_main))
      end
    end

    true
  end

  def try_flush
    @mutex.synchronize do
      if @queue.empty?
        @map.reject! {|(db,table),buffer|
          @queue << [db, table, buffer]
        }
      end
    end

    flushed = false

    until @queue.empty?
      tuple = @queue.first

      begin
        upload(*tuple)
        @queue.shift
        @error_count = 0
        flushed = true
      rescue
        if @error_count < @retry_limit
          @logger.error "Failed to upload event logs to Treasure Data, retrying: #{$!}"
          @error_count += 1
        else
          @logger.error "Failed to upload event logs to Treasure Data, trashed: #{$!}"
          $!.backtrace.each {|bt|
            @logger.info bt
          }
          @error_count = 0
          @queue.clear
        end
        return
      end
    end

    flushed
  end

  def upload(db, table, buffer)
    begin
      out = StringIO.new
      Zlib::GzipWriter.wrap(out) {|gz| gz.write buffer }
      stream = StringIO.new(out.string)

      @logger.debug "Uploading event logs to #{db}.#{table} table on Treasure Data (#{stream.size} bytes)"

      @client.import(db, table, "msgpack.gz", stream, stream.size)
    rescue TreasureData::NotFoundError
      unless @auto_create_table
        raise $!
      end
      @logger.info "Creating table #{db}.#{table} on Treasure Data"
      begin
        @client.create_log_table(db, table)
      rescue TreasureData::NotFoundError
        @client.create_database(db)
        @client.create_log_table(db, table)
      end
      retry
    end
  end

  def finalize
    close
  end

  if ConditionVariable.new.method(:wait).arity == 1
    # "WARNING: Running on Ruby 1.8. Ruby 1.9 is recommended."
    require 'timeout'
    def cond_wait(sec)
      Timeout.timeout(sec) {
        @cond.wait(@mutex)
      }
    rescue Timeout::Error
    end
  else
    def cond_wait(sec)
      @cond.wait(@mutex, sec)
    end
  end
end


end
end

