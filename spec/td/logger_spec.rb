require "spec_helper"

describe TreasureData::Logger do
  describe ".logger" do
    subject { described_class.logger }

    context ".open called" do
      before { described_class.open("tag", apikey: "dummy") }
      it { is_expected.to be_kind_of(TreasureData::Logger::TreasureDataLogger) }
    end

    context ".open_agent called" do
      before { described_class.open_agent("tag") }
      it { is_expected.to be_kind_of(Fluent::Logger::FluentLogger) }
    end

    context ".open_null called" do
      before { described_class.open_null }
      it { is_expected.to be_kind_of(Fluent::Logger::NullLogger) }
    end

    context ".open_test called" do
      before { described_class.open_test }
      it { is_expected.to be_kind_of(Fluent::Logger::TestLogger) }
    end
  end

  describe ".post" do
    let(:args) { ["tag", foo: "dummy"] }

    it "invoke TreasureData::Logger.post with args" do
      expect(TreasureData::Logger.logger).to receive(:post).with(*args)
      described_class.post(*args)
    end
  end

  describe ".post_with_time" do
    let(:args) { ["tag", {foo: "dummy"}, Time.now] }

    it "invoke TreasureData::Logger.post_with_time with args" do
      expect(TreasureData::Logger.logger).to receive(:post_with_time).with(*args)
      described_class.post_with_time(*args)
    end
  end

  describe "shortcut methods" do
    let(:klass) { TreasureData }

    describe ".logger" do
      subject{ klass.logger }

      it { is_expected.to eq TreasureData::Logger.logger }
    end

    describe ".open" do
      let(:args) { ["tag", apikey: "dummy"] }

      it "invoke TreasureData::Logger.open with args" do
        expect(TreasureData::Logger).to receive(:open).with(*args)
        klass.open(*args)
      end
    end

    describe ".open_agent" do
      let(:args) { ["tag", apikey: "dummy"] }

      it "invoke TreasureData::Logger.open_agent with args" do
        expect(TreasureData::Logger).to receive(:open_agent).with(*args)
        klass.open_agent(*args)
      end
    end

    describe ".open_null" do
      it "invoke TreasureData::Logger.open_null" do
        expect(TreasureData::Logger).to receive(:open_null).with(no_args)
        klass.open_null
      end
    end

    describe ".open_test" do
      it "invoke TreasureData::Logger.open_test" do
        expect(TreasureData::Logger).to receive(:open_test).with(no_args)
        klass.open_test
      end
    end

    describe ".post" do
      let(:args) { ["tag", foo: "dummy"] }

      it "invoke TreasureData::Logger.post with args" do
        expect(TreasureData::Logger).to receive(:post).with(*args)
        klass.post(*args)
      end
    end

    describe ".post_with_time" do
      let(:args) { ["tag", {foo: "dummy"}, Time.now] }

      it "invoke TreasureData::Logger.post_with_time with args" do
        expect(TreasureData::Logger).to receive(:post_with_time).with(*args)
        klass.post_with_time(*args)
      end
    end

    describe ".event" do
      subject{ klass.event }

      it { is_expected.to eq TreasureData::Logger.event }
    end

    describe ".log (backward compatibility)" do
      let(:args) { ["tag", foo: "dummy"] }

      it "invoke TreasureData::Logger.log with args" do
        expect(TreasureData::Logger).to receive(:post).with(*args)
        klass.log(*args)
      end
    end

    describe "Event" do
      it { expect(klass.const_get(:Event)).to eq TreasureData::Logger::Event }
    end
  end

  it "define TD as TreasureData" do
    expect(TD).to eq TreasureData
  end
end
