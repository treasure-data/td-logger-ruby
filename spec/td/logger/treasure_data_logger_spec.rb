
require 'spec_helper'

describe TreasureData::Logger::TreasureDataLogger do
  context 'init' do
    it 'with apikey' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey => 'test_1')
      expect(td.instance_variable_get(:@client).api.apikey).to eq('test_1')
      expect(td.instance_variable_get(:@client).api.instance_variable_get(:@ssl)).to eq(false)
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
end

