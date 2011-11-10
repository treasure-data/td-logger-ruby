
require 'spec_helper'

describe TreasureData::Logger::Event do
  context 'preset' do
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

    it 'action' do
      test_logger.should_receive(:post).with(:doit, {:action=>"doit", :foo=>:bar, :uid=>"uid1"}).twice
      TD.event.action(:doit, {:foo=>:bar}, "uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.action(:doit, {:foo=>:bar})
    end

    it 'register' do
      test_logger.should_receive(:post).with(:register, {:action=>"register", :uid=>"uid1"}).twice
      TD.event.register("uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.register
    end

    it 'login' do
      test_logger.should_receive(:post).with(:login, {:action=>"login", :uid=>"uid1"}).twice
      TD.event.login("uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.login
    end

    it 'pay' do
      test_logger.should_receive(:post).with(:pay, {:action=>"pay", :category=>"cat", :sub_category=>"subcat", :name=>"name", :price=>1980, :count=>1, :uid=>"uid1"}).twice
      TD.event.pay("cat", "subcat", "name", 1980, 1, "uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.pay("cat", "subcat", "name", 1980, 1)
    end
  end
end

