
require 'spec_helper'

describe TreasureData::Logger::TreasureDataLogger do
  context 'init' do
    it 'with apikey' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test_1')
      td.instance_variable_get(:@client).api.apikey.should == 'test_1'
      td.instance_variable_get(:@client).api.instance_variable_get(:@ssl).should be_false
    end

    it 'with apikey and use_ssl' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test_1', :use_ssl => true)
      td.instance_variable_get(:@client).api.apikey.should == 'test_1'
      td.instance_variable_get(:@client).api.instance_variable_get(:@ssl).should be_true
    end

    it 'db config' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test_1')
      time = Time.now
      td.should_receive(:add).with('db1', 'table1', {:foo=>:bar, :time=>time.to_i})
      td.post_with_time('table1', {:foo=>:bar}, time)
    end

    it 'fluent-logger-td compat' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test_2')
      time = Time.now
      td.should_receive(:add).with('overwrite', 'table1', {:foo=>:bar, :time=>time.to_i})
      td.post_with_time('overwrite.table1', {:foo=>:bar}, time)
    end

    ## TODO this causes real upload
    #it 'success' do
    #  td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test_3')
    #  td.post('valid', {}).should == true
    #end
  end

  context 'validate' do
    it 'validate table name' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test_4')
      proc {
        td.post('invalid-name', {})
      }.should raise_error(RuntimeError)
      proc {
        td.post('', {})
      }.should raise_error(RuntimeError)
      proc {
        td.post('9', {})
      }.should raise_error(RuntimeError)
    end

    it 'validate database name' do
      td = TreasureData::Logger::TreasureDataLogger.new('invalid-db-name', :apikey=>'test_5')
      proc {
        td.post('table', {})
      }.should raise_error(RuntimeError)
    end
  end
end

