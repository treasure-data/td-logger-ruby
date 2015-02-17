
require 'spec_helper'

describe TreasureData::Logger::Event do
  describe 'EventPreset' do
    let(:test_logger) do
      Fluent::Logger::TestLogger.new
    end
    before(:each) do
      t = test_logger
      TreasureData::Logger.module_eval do
        class_variable_set(:@@logger, t)
      end
      TD.event.attribute.clear
    end

    describe 'action' do
      context "`uid` filled" do
        it do
          expect(test_logger).to receive(:post).with(:doit, {:action=>"doit", :foo=>:bar, :uid=>"uid1"}).twice
          TD.event.action(:doit, {:foo=>:bar}, "uid1")
          TD.event.attribute[:uid] = "uid1"
          TD.event.action(:doit, {:foo=>:bar})
        end
      end

      context "`uid` unfilled" do
        it do
          expect { TD.event.action(:doit, {:foo=>:bar}, nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'register' do
      context "`uid` filled" do
        it do
          expect(test_logger).to receive(:post).with(:register, {:action=>"register", :uid=>"uid1"}).twice
          TD.event.register("uid1")
          TD.event.attribute[:uid] = "uid1"
          TD.event.register
        end
      end

      context "`uid` unfilled" do
        it do
          expect { TD.event.register(nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'login' do
      context "`uid` filled" do
        it do
          expect(test_logger).to receive(:post).with(:login, {:action=>"login", :uid=>"uid1"}).twice
          TD.event.login("uid1")
          TD.event.attribute[:uid] = "uid1"
          TD.event.login
        end
      end

      context "`uid` unfilled" do
        it do
          expect { TD.event.login(nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'pay' do
      context "`uid` filled" do
        it do
          expect(test_logger).to receive(:post).with(:pay, {:action=>"pay", :category=>"cat", :sub_category=>"subcat", :name=>"name", :price=>1980, :count=>1, :uid=>"uid1"}).twice
          TD.event.pay("cat", "subcat", "name", 1980, 1, "uid1")
          TD.event.attribute[:uid] = "uid1"
          TD.event.pay("cat", "subcat", "name", 1980, 1)
        end
      end

      context "`uid` unfilled" do
        it do
          expect { TD.event.pay("cat", "subcat", "name", 1980, 1, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "Event" do
    let(:attrs) { {default: "attr"} }
    let(:event) { TreasureData::Logger::Event.new }

    describe "#post" do
      subject { event.post(action, record) }
      let(:action) { "act" }
      let(:record) { {hello: "hello"} }

      context "with default attributes" do
        before { event.attribute = attrs }

        it "invoke TreasureData::Logger.post" do
          expect(TreasureData::Logger).to receive(:post).with(action, attrs.merge(record))
          subject
        end
      end

      context "without default attributes" do
        it "invoke TreasureData::Logger.post" do
          expect(TreasureData::Logger).to receive(:post).with(action, record)
          subject
        end
      end
    end

    describe "#post_with_time" do
      subject { event.post_with_time(action, record, time) }
      let(:action) { "act" }
      let(:record) { {hello: "hello"} }
      let(:time) { Time.now }

      context "with default attributes" do
        before { event.attribute = attrs }

        it "invoke TreasureData::Logger.post_with_time" do
          expect(TreasureData::Logger).to receive(:post_with_time).with(action, attrs.merge(record), time)
          subject
        end
      end

      context "without default attributes" do
        it "invoke TreasureData::Logger.post_with_time" do
          expect(TreasureData::Logger).to receive(:post_with_time).with(action, record, time)
          subject
        end
      end
    end
  end
end

