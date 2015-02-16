
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
end

