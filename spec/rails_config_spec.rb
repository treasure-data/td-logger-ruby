
require 'spec_helper'
require 'fileutils'
require 'logger'

TMP_DIR = File.dirname(__FILE__) + "/tmp"
FileUtils.rm_rf(TMP_DIR)

class Rails
  def self.configuration
    self.new
  end

  def self.logger
    Logger.new(STDOUT)
  end

  def self.root
    TMP_DIR
  end

  def self.env
    "test"
  end

  def middleware
    self
  end

  def use(mod)
  end
end

class ActionController
  class Base
  end
end

class ActiveSupport
  class TimeWithZone
  end
end

require 'td/logger/agent/rails'

describe TreasureData::Logger::Agent::Rails::Config do
  before(:each) do
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
    ENV.delete('TREASURE_DATA_API_KEY')
    ENV.delete('TREASURE_DATA_DB')
  end

  context 'init' do
    it 'load_env' do
      ENV['TREASURE_DATA_API_KEY'] = 'test1'
      ENV['TREASURE_DATA_DB'] = 'db1'
      c = TreasureData::Logger::Agent::Rails::Config.init
      c.disabled.should == false
      c.agent_mode?.should == false
      c.apikey.should == 'test1'
      c.database.should == 'db1'
      c.auto_create_table.should == true
    end

    it 'load_file' do
      FileUtils.mkdir_p("#{TMP_DIR}/config")
      File.open("#{TMP_DIR}/config/treasure_data.yml", "w") {|f|
        f.write <<EOF
test:
  apikey: test2
  database: db2
  debug_mode: true
EOF
      }
      c = TreasureData::Logger::Agent::Rails::Config.init
      c.disabled.should == false
      c.agent_mode?.should == false
      c.apikey.should == 'test2'
      c.database.should == 'db2'
      c.auto_create_table.should == true
      c.debug_mode.should == true
    end

    it 'load_file without test' do
      FileUtils.mkdir_p("#{TMP_DIR}/config")
      File.open("#{TMP_DIR}/config/treasure_data.yml", "w") {|f|
        f.write <<EOF
development:
  apikey: test2
  database: db2
  debug_mode: true
EOF
      }
      c = TreasureData::Logger::Agent::Rails::Config.init
      c.disabled.should == true
    end

    it 'prefer file than env' do
      ENV['TREASURE_DATA_API_KEY'] = 'test3'
      ENV['TREASURE_DATA_DB'] = 'db3'

      FileUtils.mkdir_p("#{TMP_DIR}/config")
      File.open("#{TMP_DIR}/config/treasure_data.yml", "w") {|f|
        f.write <<EOF
test:
  apikey: test4
  database: db4
  auto_create_table: false
EOF
      }
      c = TreasureData::Logger::Agent::Rails::Config.init
      c.disabled.should == false
      c.agent_mode?.should == false
      c.apikey.should == 'test4'
      c.database.should == 'db4'
      c.auto_create_table.should == false
      c.debug_mode.should == false
    end

    it 'agent mode' do
      FileUtils.mkdir_p("#{TMP_DIR}/config")
      File.open("#{TMP_DIR}/config/treasure_data.yml", "w") {|f|
        f.write <<EOF
test:
  agent: localhost
  tag: td.db5
EOF
      }
      c = TreasureData::Logger::Agent::Rails::Config.init
      c.disabled.should == false
      c.agent_mode?.should == true
      c.tag.should == 'td.db5'
      c.agent_host.should == 'localhost'
      c.agent_port.should == 24224
    end

    it 'test mode' do
      FileUtils.mkdir_p("#{TMP_DIR}/config")
      File.open("#{TMP_DIR}/config/treasure_data.yml", "w") {|f|
        f.write <<EOF
test:
  agent: localhost
  tag: td.db5
  test_mode: true
EOF
      }
      c = TreasureData::Logger::Agent::Rails::Config.init
      c.disabled.should == false
      c.test_mode?.should == true
    end
  end
end

describe ActiveSupport::TimeWithZone do
  it 'has to_msgpack' do
    ActiveSupport::TimeWithZone.method_defined?(:to_msgpack).should be_true
  end
end
