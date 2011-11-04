
require 'spec_helper'

describe TreasureData::Logger::Event do
  context 'preset' do
    let(:test_logger) do
      Fluent::Logger::TestLogger.new
    end
    before(:each) do
      t = test_logger
      TreasureData::Logger.class_variable_set(:@@logger, t)
      TD.event.attribute.clear
    end

    it 'action' do
      test_logger.should_receive(:post).with(:doit, {:foo=>:bar, :uid=>"uid1"}, nil).twice
      TD.event.action(:doit, {:foo=>:bar}, "uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.action(:doit, {:foo=>:bar})
    end

    it 'register' do
      test_logger.should_receive(:post).with(:register, {:uid=>"uid1"}, nil).twice
      TD.event.register("uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.register
    end

    it 'login' do
      test_logger.should_receive(:post).with(:login, {:uid=>"uid1"}, nil).twice
      TD.event.login("uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.login
    end

    it 'pay' do
      test_logger.should_receive(:post).with(:pay, {:category=>"cat", :sub_category=>"subcat", :name=>"name", :price=>1980, :count=>1, :uid=>"uid1"}, nil).twice
      TD.event.pay("cat", "subcat", "name", 1980, 1, "uid1")
      TD.event.attribute[:uid] = "uid1"
      TD.event.pay("cat", "subcat", "name", 1980, 1)
    end
  end
end

