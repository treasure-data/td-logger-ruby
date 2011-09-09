
module TreasureData
module Logger

# TODO shutdown handler  (deadlock)

class TreasureDataLogger < Fluent::Logger::LoggerBase
  def initialize(apikey, tag, auto_create_table)
    require 'thread'
    require 'stringio'
    require 'zlib'
    require 'msgpack'
    require 'time'
    require 'net/http'
    require 'cgi'
    require 'logger'
    require 'td/client'

    @tag = tag
    @auto_create_table = auto_create_table
    @logger = ::Logger.new(STDERR)

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
    @upload_thread = Thread.new(&method(:upload_main))
  end

  attr_accessor :logger

  def close
    @finish = true
    @mutex.synchronize {
      @flush_now = true
      @cond.signal
    }
  end

  def post(tag, record)
    tag = "#{@tag}.#{tag}"
    db, table = tag.split('.')[-2, 2]

    record['time'] ||= Time.now.to_i

    key = [db, table]
    @mutex.synchronize do
      buffer = (@map[key] ||= '')
      record.to_msgpack(buffer)

      if buffer.size > @chunk_limit
        @queue << [db, table, buffer]
        @map.delete(key)
        @cond.signal
      end
    end

    nil
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
          @logger.error "Failed to upload logs to Treasure Data, retrying: #{$!}"
          @error_count += 1
        else
          @logger.error "Failed to upload logs to Treasure Data, trashed: #{$!}"
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
    out = StringIO.new
    Zlib::GzipWriter.wrap(out) {|gz| gz.write buffer }
    stream = StringIO.new(out.string)

    begin
      @client.import(db, table, "msgpack.gz", stream, stream.size)
    rescue TreasureData::NotFoundError
      unless @auto_create_table
        raise $!
      end
      @logger.info "Creating table #{db}.#{table} on TreasureData"
      begin
        @client.create_log_table(db, table)
      rescue TreasureData::NotFoundError
        @client.create_database(db)
        @client.create_log_table(db, table)
      end
      retry
    end
  end

  def e(s)
    CGI.escape(s.to_s)
  end

  if ConditionVariable.new.method(:wait).arity == 1
    #$log.warn "WARNING: Running on Ruby 1.8. Ruby 1.9 is recommended."
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

