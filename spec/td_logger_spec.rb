
require 'spec_helper'

describe TreasureData::Logger::TreasureDataLogger do
  context 'init' do
    it 'db config' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test')
      time = Time.now
      td.should_receive(:add).with('db1', 'table1', {:foo=>:bar, :time=>time.to_i})
      td.post_with_time('table1', {:foo=>:bar}, time)
    end

    it 'fluent-logger-td compat' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test')
      time = Time.now
      td.should_receive(:add).with('overwrite', 'table1', {:foo=>:bar, :time=>time.to_i})
      td.post_with_time('overwrite.table1', {:foo=>:bar}, time)
    end

    it 'success' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test')
      td.post('valid', {}).should == true
    end
  end

  context 'validate' do
    it 'validate table name' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test')
      td.post('invalid-name', {}).should == false
      td.post('', {}).should == false
      td.post('9', {}).should == false
    end

    it 'validate database name' do
      td = TreasureData::Logger::TreasureDataLogger.new('invalid-db-name', :apikey=>'test')
      td.post('table', {}).should == false
    end
  end
end

