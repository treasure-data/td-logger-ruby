
require 'spec_helper'
require 'fileutils'
require 'logger'

TMP_DIR = REPO_ROOT.join("tmp")
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
      expect(c.disabled).to eq(false)
      expect(c.agent_mode?).to eq(false)
      expect(c.apikey).to eq('test1')
      expect(c.database).to eq('db1')
      expect(c.auto_create_table).to eq(true)
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
      expect(c.disabled).to eq(false)
      expect(c.agent_mode?).to eq(false)
      expect(c.apikey).to eq('test2')
      expect(c.database).to eq('db2')
      expect(c.auto_create_table).to eq(true)
      expect(c.debug_mode).to eq(true)
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
      expect(c.disabled).to eq(true)
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
      expect(c.disabled).to eq(false)
      expect(c.agent_mode?).to eq(false)
      expect(c.apikey).to eq('test4')
      expect(c.database).to eq('db4')
      expect(c.auto_create_table).to eq(false)
      expect(c.debug_mode).to eq(false)
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
      expect(c.disabled).to eq(false)
      expect(c.agent_mode?).to eq(true)
      expect(c.tag).to eq('td.db5')
      expect(c.agent_host).to eq('localhost')
      expect(c.agent_port).to eq(24224)
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
      expect(c.disabled).to eq(false)
      expect(c.test_mode?).to eq(true)
    end
  end
end

describe ActiveSupport::TimeWithZone do
  it 'has to_msgpack' do
    expect(ActiveSupport::TimeWithZone.method_defined?(:to_msgpack)).to eq(true)
  end
end
