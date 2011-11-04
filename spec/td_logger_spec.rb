
require 'spec_helper'

describe TreasureData::Logger::TreasureDataLogger do
  context 'init' do
    it 'db config' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test')
      time = Time.now
      td.should_receive(:add).with('db1', 'table1', {:foo=>:bar, :time=>time.to_i})
      td.post('table1', {:foo=>:bar}, time)
    end

    it 'fluent-logger-td compat' do
      td = TreasureData::Logger::TreasureDataLogger.new('db1', :apikey=>'test')
      time = Time.now
      td.should_receive(:add).with('overwrite', 'table1', {:foo=>:bar, :time=>time.to_i})
      td.post('overwrite.table1', {:foo=>:bar}, time)
    end
  end
end

