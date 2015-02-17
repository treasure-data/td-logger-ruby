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

require 'td/logger/agent/rails' # NOTE: should be require after Rails goodies mocked

describe TreasureData::Logger::Agent::Rails do
  describe "#init" do
    shared_examples_for "setup Rails hooks" do
      it "returns true" do
        expect(subject).to eq true
      end

      it "middleware setup" do
        expect(rails).to receive(:middleware).and_return(rails);
        subject
      end

      it "Rack hooks register" do
        expect(TreasureData::Logger::Agent::Rack::Hook).to receive(:before)
        subject
      end

      it "TreasureData::Logger.event.attribute.clear registered on before hook" do
        expect { subject }.to change{
          # TODO: should be refactor later @@before
          TreasureData::Logger::Agent::Rack::Hook.class_variable_get(:@@before).length
        }.by(1)
      end

      it "registerd before hook called TreasureData::Logger.event.attribtue.clear" do
        subject # for register hooks
        null = double.as_null_object
        allow(TreasureData::Logger).to receive(:event).and_return(null)
        allow(null).to receive(:attribtue).and_return(null)

        # TODO: should be refactor later @@before
        TreasureData::Logger::Agent::Rack::Hook.class_variable_get(:@@before).last.call
        expect(null).to have_received(:clear)
      end

      it "mixin ControllerExtension" do
        expect(TreasureData::Logger::Agent::Rails::ControllerExtension).to receive(:init)
        subject
      end
    end

    let(:config) { TreasureData::Logger::Agent::Rails::Config.new }
    let(:rails) { Rails.new }

    before { allow(TreasureData::Logger::Agent::Rails::Config).to receive(:init).and_return(config) }
    before do
      fixture_of_methods.each do |method, value|
        allow(config).to receive(method).and_return(value)
      end
    end

    subject { TreasureData::Logger::Agent::Rails.init(rails) }

    context "config.disable = true" do
      let(:fixture_of_methods) { {disabled: true} }

      it { expect(subject).to eq false }
      it { expect(::TreasureData::Logger).to receive(:open_null).with(no_args); subject }
    end

    context "config.test_mode? == true" do
      let(:fixture_of_methods) { {disabled: false, "test_mode?" => true} }

      it_behaves_like "setup Rails hooks"
      it { expect(::TreasureData::Logger).to receive(:open_test).with(no_args); subject }
    end

    context "config.agent_mode? == true" do
      let(:fixture_of_methods) { {
        disabled: false,
        "test_mode?" => false,
        "agent_mode?" => true,
        tag: "tag",
        agent_host: "agent-host",
        agent_port: "9999",
        debug_mode: "debug"
      } }

      it_behaves_like "setup Rails hooks"
      it {
        expect(::TreasureData::Logger).to receive(:open_agent).with(config.tag, {host: config.agent_host, port: config.agent_port, debug: config.debug_mode})
        subject
      }
    end

    context "config.agent_mode? and test_mode? both false" do
      let(:fixture_of_methods) { {
        disabled: false,
        "test_mode?" => false,
        "agent_mode?" => false,
        apikey: "APIKEY",
        database: "DB",
        auto_create_table: true,
        debug_mode: "debug"
      } }

      it_behaves_like "setup Rails hooks"
      it {
        expect(::TreasureData::Logger).to receive(:open).with(config.database, apikey: config.apikey, auto_create_table: config.auto_create_table, debug: config.debug_mode)
        subject
      }
    end
  end
end


describe ActiveSupport::TimeWithZone do
  it 'has to_msgpack' do
    expect(ActiveSupport::TimeWithZone.method_defined?(:to_msgpack)).to eq(true)
  end
end
