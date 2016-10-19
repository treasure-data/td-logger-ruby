
require 'spec_helper'

describe TreasureData::Logger::TreasureDataLogger do
  context 'init' do
    it 'with apikey' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1')
      expect(td.instance_variable_get(:@client).api.apikey).to eq('test_1')
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@ssl)).to eq(true)
    end

    it 'with apikey and use_ssl' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1', :use_ssl => true)
      expect(td.instance_variable_get(:@client).api.apikey).to eq('test_1')
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@ssl)).to eq(true)
    end

    it 'with apikey and ssl' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1', :ssl => true)
      expect(td.instance_variable_get(:@client).api.apikey).to eq('test_1')
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@ssl)).to eq(true)
    end

    it 'with apikey and HTTP endpoint' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1', :endpoint => "http://idontexi.st")
      expect(td.instance_variable_get(:@client).api.apikey).to eq('test_1')
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@host)).to eq("idontexi.st")
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@port)).to eq(80)
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@ssl)).to eq(false)
    end

    it 'with apikey and HTTPS endpoint' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1', :endpoint => "https://idontexi.st")
      expect(td.instance_variable_get(:@client).api.apikey).to eq('test_1')
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@host)).to eq("idontexi.st")
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@port)).to eq(443)
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@ssl)).to eq(true)
    end

    it 'db config' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1')
      time = Time.now
      expect(td).to receive(:add).with('db1', 'table1', {:foo => :bar, :time => time.to_i})
      td.post_with_time('table1', {:foo => :bar}, time)
    end

    it 'fluent-logger-td compat' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_2')
      time = Time.now
      expect(td).to receive(:add).with('overwrite', 'table1', {:foo => :bar, :time => time.to_i})
      td.post_with_time('overwrite.table1', {:foo => :bar}, time)
    end

    ## TODO this causes real upload
    #it 'success' do
    #  td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_3')
    #  td.post('valid', {}).should == true
    #end
  end

  context 'validate' do
    it 'validate table name' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_4')
      expect {
        td.post('invalid-name', {})
      }.to raise_error(RuntimeError)
      expect {
        td.post('', {})
      }.to raise_error(RuntimeError)
      expect {
        td.post('9', {})
      }.to raise_error(RuntimeError)
    end

    it 'validate database name' do
      td = TreasureData::Logger::TreasureDataLogger.new('invalid-db-name', :apikey => 'test_5')
      expect {
        td.post('table', {})
      }.to raise_error(RuntimeError)
    end
  end

  it "raise error if `apikey` option is missing" do
    expect{ described_class.new("dummy-tag", {}) }.to raise_error(ArgumentError)
  end

  describe "#logger" do
    let(:tag_prefix) { "dummy" }

    subject { described_class.new(tag_prefix, {apikey: "dummy"}.merge(options)).logger }

    context "`debug` option given" do
      let(:options) { {debug: true} }

      it { expect(subject.level).to eq ::Logger::DEBUG }
    end

    context "not `debug` option given" do
      let(:options) { {} }

      it { expect(subject.level).to eq ::Logger::INFO }
    end
  end

  describe "#post_with_time" do
    let(:td) { described_class.new(prefix, {apikey: 'test_1'}.merge(options)) }
    let(:tag) { "foo.bar" }
    let(:time) { Time.now }
    let(:prefix) { "dummy" }
    let(:record) { {greeting: "hello", time: 1234567890} }
    let(:options) { {} }

    subject { td.post_with_time(tag, record, time) }

    describe "db and table" do
      context "no `tag_prefix` option given" do
        let(:prefix) { "" }

        it "`db` and `table` determine with tag" do
          db, table = tag.split(".")[-2, 2]
          allow(td).to receive(:add).with(db, table, record)
          subject
        end
      end

      context "`tag_prefix` option given" do
        let(:prefix) { "prefix" }

        it "`db` and `table` determine with tag and tag_prefix" do
          db, table = "#{prefix}.#{tag}".split(".")[-2, 2]
          allow(td).to receive(:add).with(db, table, record)
          subject
        end
      end
    end

    describe "inject time to record" do
      context "record has no `:time` key" do
        let(:record) { {greeting: "hello"} }

        it "fill-in :time key with `time` argument" do
          allow(td).to receive(:add).with(anything, anything, record.merge(time: time.to_i))
          subject
        end
      end

      context "record has `:time` key" do
        let(:record) { {greeting: "hello", time: 1234567890 } }

        it do
          allow(td).to receive(:add).with(anything, anything, record)
          subject
        end
      end
    end
  end

  describe "#add" do
    let(:td) { described_class.new(prefix, {apikey: 'test_1'}) }
    let(:prefix) { "prefix" }
    let(:db) { "database" }
    let(:table) { "table" }
    let(:valid_message) { {"foo" => "FOO", "bar" => "BAR"} }

    before do
      # don't try to upload data causing by `at_exit { close }` that registered at TreasureDataLogger#initialize
      # this hack causes "zlib(finalizer): Zlib::GzipWriter object must be closed explicitly." warning, but ignoreable for our tests..
      allow_any_instance_of(TreasureData::Logger::TreasureDataLogger).to receive(:at_exit).and_return(true)
    end

    subject { td.send(:add, db, table, message) } # NOTE: `add` is private method

    describe "message type" do
      shared_examples_for "should fail `add` because not a hash" do
        it { is_expected.to eq false }
        it "logging error" do
          expect(td.logger).to receive(:error).with(/TreasureDataLogger: record must be a Hash:/)
          subject
        end
      end

      context "string" do
        let(:message) { "string" }
        it_behaves_like "should fail `add` because not a hash"
      end

      context "array" do
        let(:message) { ["hello"] }
        it_behaves_like "should fail `add` because not a hash"
      end

      context "fixnum" do
        let(:message) { 42 }
        it_behaves_like "should fail `add` because not a hash"
      end

      context "hash" do
        let(:message) { {foo: 42} }

        it { is_expected.to eq true }
      end
    end

    describe "queue is full" do
      let(:queue) { td.instance_variable_get(:@queue) }
      let(:max) { td.instance_variable_get(:@queue_limit) }
      let(:message) { valid_message }

      before do
        (max + 1).times { queue << [db, table, {"foo" => "bar"}.to_msgpack] }
      end

      it { is_expected.to eq false }
      it do
        expect(td.logger).to receive(:error).with(/TreasureDataLogger: queue length exceeds limit. can't add new event log:/)
        subject
      end
    end

    describe "if `to_msgpack` failed" do
      let(:message) { valid_message }

      before { allow(td).to receive(:to_msgpack) { raise "something error" } }

      it { is_expected.to eq false }
      it do
        expect(td.logger).to receive(:error).with(/TreasureDataLogger: Can't convert to msgpack:/)
        subject
      end
    end

    describe "buffer size/cardinality check" do
      let(:max) { TreasureData::Logger::TreasureDataLogger::MAX_KEY_CARDINALITY }
      let(:warn) { TreasureData::Logger::TreasureDataLogger::WARN_KEY_CARDINALITY }
      let(:map_key) { [db, table] }
      let(:record_keys) { max.times }
      let(:message) { record_keys.inject({}){|r, n| r[n] = n; r } }

      context "buffer size == MAX_KEY_CARDINALITY" do
        it { is_expected.to eq true }
      end

      context "buffer size > MAX_KEY_CARDINALITY" do
        let(:record_keys) { (max + 1).times }

        it { is_expected.to eq false }
        it do
          expect(td.logger).to receive(:error).with(/TreasureDataLogger: kind of keys in a buffer exceeds/)
          expect(td.instance_variable_get(:@map)).to receive(:delete).with(map_key)
          subject
        end
      end

      context "before <= WARN && WARN < after" do
        let(:record_keys) { (warn + 1).times } # just one key

        it do
          expect(td.logger).to receive(:warn).with("TreasureDataLogger: kind of keys in a buffer exceeds #{warn} which is too large. please check the schema design.")
          subject
        end
      end

      context "buffer.size > @chunk_limit" do
        let(:chunk_limit) { 0 }

        before { td.instance_variable_set(:@chunk_limit, chunk_limit) }

        it do
          expect(td.instance_variable_get(:@queue)).to receive(:<<).with([db, table, anything])
          expect(td.instance_variable_get(:@map)).to receive(:delete).with(map_key)
          expect(td.instance_variable_get(:@cond)).to receive(:signal)
          subject
        end
      end
    end
  end

  describe "#to_msgpack" do
    let(:td) { described_class.new("prefix", {apikey: 'test_1'}) }

    subject { td.send(:to_msgpack, target) }

    shared_examples_for "original to_msgpack only invoked" do
      after { subject }

      it { expect(target).to receive(:to_msgpack) }
      it { expect(JSON).to_not receive(:dump) }
      it { expect(JSON).to_not receive(:load) }
    end

    shared_examples_for "JSON.load/dump then to_msgpack invoke" do
      after { subject }

      it { expect(JSON).to receive(:dump).with(target) }
      it { expect(JSON).to receive(:load) }
    end

    context "have to_msgpack objects" do
      # see also for official supported objects: https://github.com/msgpack/msgpack-ruby/blob/master/ext/msgpack/core_ext.c
      context "string" do
        let(:target) { "foobar" }
        it_behaves_like "original to_msgpack only invoked"
      end

      context "array" do
        let(:target) { [1] }
        it_behaves_like "original to_msgpack only invoked"
      end

      context "hash" do
        let(:target) { {foo: "foo"} }
        it_behaves_like "original to_msgpack only invoked"
      end

      context "time" do
        let(:target) { Time.now }
        it_behaves_like "original to_msgpack only invoked"
      end
    end

    context "have not to_msgpack objects" do
      context "date" do
        let(:target) { Date.today }
        it_behaves_like "JSON.load/dump then to_msgpack invoke"
      end

      context "class" do
        let(:target) { Class.new }
        it_behaves_like "JSON.load/dump then to_msgpack invoke"
      end
    end
  end

  describe "#upload" do
    let(:td) { described_class.new(prefix, options) }
    let(:prefix) { "prefix" }
    let(:options) { {apikey: "apikey"} }
    let(:db) { "database" }
    let(:table) { "table" }
    let(:message) { {foo: "FOO"} }

    subject { td.send(:upload, db, table, message.to_msgpack) } # NOTE: `upload` is private method

    describe "TreasureDataLogger::Client#import success" do
      context 'unuse unique_key' do
        it do
          expect(td.instance_variable_get(:@client)).to receive(:import).with(db, table, "msgpack.gz", anything, anything, nil)
          subject
        end
      end

      context 'use unique_key' do
        let(:options) { {apikey: "apike", use_unique_key: true} }

        it do
          expect(td.instance_variable_get(:@client)).to receive(:import).with(db, table, "msgpack.gz", anything, anything, kind_of(String))
          subject
        end
      end
    end

    describe "TreasureDataLogger::NotFoundError" do
      let(:client) { td.instance_variable_get(:@client) }

      before do
        # NOTE: raise "not found" client.import at first called, but second and later call not raise
        queue = [true]
        allow(client).to receive(:import){
          raise TreasureData::NotFoundError, "not found" if queue.shift
          true
        }
      end

      context "auto_create_table options disabled" do
        let(:options) { {apikey: "apikey", auto_create_table: false} }

        it do
          expect{ subject }.to raise_error(TreasureData::NotFoundError)
        end
      end

      context "auto_create_table options enabled" do
        let(:options) { {apikey: "apikey", auto_create_table: true} }

        it "try to create table with exists database" do
          expect(client).to receive(:create_log_table)
          subject
        end

        it "try to create table with no exists databae" do
          queue = [true]
          allow(client).to receive(:create_log_table){ raise TreasureData::NotFoundError, "not found again" if queue.shift}
          expect(client).to receive(:create_database)
          subject
        end

        it "retry @client.import after create table" do
          expect(client).to receive(:create_log_table)
          expect(client).to receive(:import).twice # second call is retry
          subject
        end
      end
    end
  end

  describe "#flush" do
    let(:td) { described_class.new("prefix", {apikey: 'test_1'}) }
    let(:db) { "database" }
    let(:table) { "table" }

    subject { td.flush }

    before { allow(td).to receive(:try_flush) } # do not call try_flush actually, try_flush test is in other place

    it "lock mutex and release" do
      expect(td.instance_variable_get(:@mutex)).to receive(:lock)
      expect(td.instance_variable_get(:@mutex)).to receive(:unlock)
      subject
    end

    it "call #try_flush" do
      expect(td).to receive(:try_flush).with(no_args)
      subject
    end

    it "@map to be flushed (enqueue)" do
      buffer = TreasureData::Logger::TreasureDataLogger::Buffer.new
      td.instance_variable_set(:@map, {[db, table] => buffer})
      expect(td.instance_variable_get(:@queue)).to receive(:<<).with([db, table, buffer.flush!])
      subject
    end

    it "rescue anything error" do
      allow(td).to receive(:try_flush){ raise "something error" }
      expect(td.instance_variable_get(:@logger)).to receive(:error).with(/Unexpected error at flush:/)
      expect(td.instance_variable_get(:@logger)).to receive(:info).at_least(1) # backtrace
      expect(td.instance_variable_get(:@mutex)).to_not be_locked
      subject
    end
  end

  describe "#try_flush" do
    let(:td) { described_class.new("prefix", {apikey: 'test_1'}) }
    let(:db) { "database" }
    let(:table) { "table" }

    let(:mutex) { td.instance_variable_get(:@mutex) }
    let(:queue) { td.instance_variable_get(:@queue) }
    let(:logger) { td.instance_variable_get(:@logger) }

    let(:buffer) { TreasureData::Logger::TreasureDataLogger::Buffer.new }

    before { allow_any_instance_of(TreasureData::Logger::TreasureDataLogger).to receive(:at_exit).and_return(true) }
    before { mutex.lock } # try_flush is expected mutex locked that called
    after { mutex.unlock }

    subject { td.send(:try_flush) }

    describe "force flush small buffers if queue is empty" do

      before { allow(td).to receive(:upload) }  # do not call `upload` actually, that method test is in other place
      before { td.instance_variable_set(:@map, {[db, table] => buffer}) } # dummy data append

      context "queue is empty" do
        it do
          expect(queue).to receive(:<<).with([db, table, anything])
          subject
        end
      end

      context "queue is not empty" do
        before { queue << [db, table, buffer.flush!] }

        it do
          expect(queue).to_not receive(:<<).with([db, table, anything])
          subject
        end
      end
    end

    context "queue and on-memory buffer are empty" do
      before { allow(td).to receive(:upload) }  # do not call `upload` actually, that method test is in other place

      it "return false" do
        is_expected.to eq false
      end

      it "don't call #upload" do
        expect(td).to_not receive(:upload)
        subject
      end
    end

    context "some data having" do
      describe "queue to upload" do
        before do
          times.times do |n|
            buf = TreasureData::Logger::TreasureDataLogger::Buffer.new
            buf.append(n)
            queue << [db, table, buf.flush!]
          end
        end

        context "100 queue" do
          let(:times) { 100 }

          it "call upload 100 times" do
            expect(td).to receive(:upload).exactly(times)
            subject
          end
        end
      end

      describe "upload fail" do
        before do
          100.times do |n|
            buf = TreasureData::Logger::TreasureDataLogger::Buffer.new
            buf.append(n)
            queue << [db, table, buf.flush!]
          end
        end

        # NOTE: @retry_limit is hard coded as 12 
        before do
          times = error_times.times.to_a
          allow(td).to receive(:upload){
            if n = times.shift
              raise "something error (#{n})"
            else
              true
            end
          }
        end

        context "errors 0 times" do
          let(:error_times) { 0 }

          it { expect(logger).to_not receive(:info); subject }
          it { expect(logger).to_not receive(:error); subject }
        end

        context "errors 1 times" do
          let(:error_times) { 1 }

          it do
            expect(queue).to_not receive(:clear)
            subject
          end

          it do
            expect(logger).to receive(:error).with(/Failed to upload event logs to Treasure Data, retrying:/)
            subject
          end

          it "not trash" do
            expect(logger).to_not receive(:error).with(/Failed to upload event logs to Treasure Data, trashed:/)
            subject
          end

          it "error_count should reset" do
            expect(td.instance_variable_get(:@error_count)).to eq 0
            subject
          end
        end

        context "errors 20 times" do
          let(:error_times) { 20 }

          it do
            skip "try_flush has bug?"
            expect(queue).to receive(:clear)
            subject
          end

          it do
            skip "try_flush has bug?"
            expect(logger).to receive(:error).with(/Failed to upload event logs to Treasure Data, retrying:/)
            expect(logger).to receive(:error).with(/Failed to upload event logs to Treasure Data, trashed:/)
            subject
          end

          it do
            skip "try_flush has bug?"
            expect(queue).to_not receive(:clear)
            subject
          end

          it "output backtrace as INFO level" do
            skip "try_flush has bug?"
            expect(logger).to receive(:info).at_least(1) # backtrace
            subject
          end

          it "error_count should reset" do
            skip "try_flush has bug?"
            expect(td.instance_variable_get(:@error_count)).to eq 0
            subject
          end
        end
      end
    end
  end

  describe "#close" do
    let(:td) { described_class.new("prefix", {apikey: 'test_1'}) }
    let(:db) { "database" }
    let(:table) { "table" }
    let(:queue) { td.instance_variable_get(:@queue) }
    let(:logger) { td.instance_variable_get(:@logger) }

    subject { td.close }

    context "queue is empty" do
      it do
        expect(td).to_not receive(:upload)
        subject
      end
    end

    context "queue is not empty" do
      before { queue << [db, table, TreasureData::Logger::TreasureDataLogger::Buffer.new.flush!] }

      context "upload success" do
        it do
          expect(td).to receive(:upload)
          subject
        end
      end

      context "upload fail" do
        it do
          allow(td).to receive(:upload){ raise "something error"}
          expect(logger).to receive(:error).with(/Failed to upload event logs to Treasure Data, trashed:/)
          subject
        end
      end
    end

    context "@map is empty" do
      it do
        expect(td).to_not receive(:upload)
        subject
      end
    end

    context "@map is not empty" do
      before do
        buffer = TreasureData::Logger::TreasureDataLogger::Buffer.new
        td.instance_variable_set(:@map, {[db, table] => buffer})
      end

      context "upload success" do
        it do
          expect(td).to receive(:upload)
          subject
        end
      end

      context "upload fail" do
        it do
          allow(td).to receive(:upload){ raise "something error" }
          expect(logger).to receive(:error).with(/Failed to upload event logs to Treasure Data, trashed:/)
          subject
        end
      end
    end
  end
end

