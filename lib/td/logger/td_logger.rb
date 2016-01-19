module TreasureData
module Logger


class TreasureDataLogger < Fluent::Logger::LoggerBase
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

    # translate :use_ssl to :ssl for backwards compatibility
    options[:ssl] = options[:use_ssl] unless options[:use_ssl].nil?
    @client = TreasureData::Client.new(apikey, options)

    @mutex = Mutex.new
    @cond = ConditionVariable.new
    @map = {}  # (db,table) => buffer:String
    @queue = []

    @chunk_limit = options[:chunk_limit] || 8 * 1024 * 1024
    @queue_limit = 50

    @flush_interval = options[:flush_interval] || 2
    @max_flush_interval = options[:max_flush_interval] || 300
    @retry_wait = 1.0
    @retry_limit = 12

    @finish = false
    @next_time = Time.now.to_i + @flush_interval
    @error_count = 0

    # start thread when the first post() is called for
    # Unicorn and Passenger.
    @upload_thread = nil

    @use_unique_key = options[:use_unique_key]

    # The calling order of finalizer registered by define_finalizer is indeterminate,
    # so we should use at_exit instead for memory safety.
    at_exit { close }
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

      @queue.reject! {|db,table,data|
        begin
          upload(db, table, data)
          true
        rescue
          @logger.error "Failed to upload event logs to Treasure Data, trashed: #{$!}"
          false
        end
      }
      @map.reject! {|(db,table),buffer|
        data = buffer.flush!
        begin
          upload(db, table, data)
          true
        rescue
          @logger.error "Failed to upload event logs to Treasure Data, trashed: #{$!}"
          false
        end
      }
    end
  end

  def flush
    @mutex.lock

    # Move small chunks into queue to flush all events.
    # See try_flush routine for more detail
    @map.reject! {|(db,table),buffer|
      data = buffer.flush!
      @queue << [db, table, data]
    }
    try_flush
  rescue => e
    @logger.error "Unexpected error at flush: #{e}"
    e.backtrace.each {|bt|
      @logger.info bt
    }
  ensure
    @mutex.unlock
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
        flushed = try_flush
        @flush_now = false
      end

      if @error_count == 0
        if flushed && @flush_interval < @max_flush_interval
          @flush_interval = [@flush_interval ** 2, @max_flush_interval].min
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
  MAX_KEY_CARDINALITY = 512
  WARN_KEY_CARDINALITY = 256

  class Buffer
    def initialize
      @key_set = {}
      @data = StringIO.new
      @gz = Zlib::GzipWriter.new(@data)
    end

    def key_set_size
      @key_set.size
    end

    def update_key_set(record)
      record.each_key {|key|
        @key_set[key] = true
      }
      @key_set.size
    end

    def append(data)
      @gz << data
    end

    def size
      @data.size
    end

    def flush!
      close
      @data.string
    end

    def close
      @gz.close unless @gz.closed?
    end
  end

  def to_msgpack(msg)
    begin
      msg.to_msgpack
    rescue NoMethodError
      JSON.load(JSON.dump(msg)).to_msgpack
    end
  end

  def add(db, table, msg)
    # NOTE: TreasureData::API is defined at td-client-ruby gem
    #       https://github.com/treasure-data/td-client-ruby/blob/master/lib/td/client/api.rb
    begin
      TreasureData::API.validate_database_name(db)
    rescue
      @logger.error "TreasureDataLogger: Invalid database name #{db.inspect}: #{$!}"
      raise "Invalid database name #{db.inspect}: #{$!}"
    end
    begin
      TreasureData::API.validate_table_name(table)
    rescue
      @logger.error "TreasureDataLogger: Invalid table name #{table.inspect}: #{$!}"
      raise "Invalid table name #{table.inspect}: #{$!}"
    end

    begin
      data = to_msgpack(msg)
    rescue
      @logger.error("TreasureDataLogger: Can't convert to msgpack: #{msg.inspect}: #{$!}")
      return false
    end

    key = [db, table]

    @mutex.synchronize do
      if @queue.length > @queue_limit
        @logger.error("TreasureDataLogger: queue length exceeds limit. can't add new event log: #{msg.inspect}")
        return false
      end

      buffer = (@map[key] ||= Buffer.new)

      record = MessagePack.unpack(data)
      unless record.is_a?(Hash)
        @logger.error("TreasureDataLogger: record must be a Hash: #{msg.inspect}")
        return false
      end

      before = buffer.key_set_size
      after = buffer.update_key_set(record)
      if after > MAX_KEY_CARDINALITY
        @logger.error("TreasureDataLogger: kind of keys in a buffer exceeds #{MAX_KEY_CARDINALITY}.")
        @map.delete(key)
        return false
      end
      if before <= WARN_KEY_CARDINALITY && after > WARN_KEY_CARDINALITY
        @logger.warn("TreasureDataLogger: kind of keys in a buffer exceeds #{WARN_KEY_CARDINALITY} which is too large. please check the schema design.")
      end

      buffer.append(data)

      if buffer.size > @chunk_limit
        # flush this buffer
        data = buffer.flush!
        @queue << [db, table, data]
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

  # assume @mutex is locked
  def try_flush
    # force flush small buffers if queue is empty
    if @queue.empty?
      @map.reject! {|(db,table),buffer|
        data = buffer.flush!
        @queue << [db, table, data]
      }
    end

    if @queue.empty?
      return false
    end

    flushed = false

    @mutex.unlock
    begin
      until @queue.empty?
        db, table, data = @queue.first

        begin
          upload(db, table, data)
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
          return nil

        end
      end

    ensure
      @mutex.lock
    end

    return flushed
  end

  def upload(db, table, data)
    unique_key = @use_unique_key ? generate_unique_key : nil

    begin
      stream = StringIO.new(data)

      @logger.info "Uploading event logs to #{db}.#{table} table on Treasure Data (#{stream.size} bytes)"

      @client.import(db, table, "msgpack.gz", stream, stream.size, unique_key)
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

  # NOTE fluentd unique_id and fluent-plugin-td unique_str in reference.
  #      https://github.com/fluent/fluentd/blob/v0.12.15/lib/fluent/plugin/buf_memory.rb#L22
  #      https://github.com/treasure-data/fluent-plugin-td/blob/v0.10.27/lib/fluent/plugin/out_tdlog.rb#L225
  def generate_unique_key(now = Time.now)
    u1 = ((now.to_i*1000*1000+now.usec) << 12 | rand(0xfff))
    uid = [u1 >> 32, u1 & 0xffffffff, rand(0xffffffff), rand(0xffffffff)].pack('NNNN')
    uid.unpack('C*').map { |x| "%02x" % x }.join
  end

  require 'thread'  # ConditionVariable
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

