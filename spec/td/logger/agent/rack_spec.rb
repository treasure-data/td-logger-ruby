require 'spec_helper'
require "rack/mock"
require 'td/logger/agent/rack'

describe TreasureData::Logger::Agent::Rack::Hook do
  def app
    @app ||= Rack::Builder.new {
      use TreasureData::Logger::Agent::Rack::Hook
      run lambda {|env| [200, {}, ["body"]]}
    }.to_app
  end

  let(:dummy_object) { double.as_null_object }

  subject { Rack::MockRequest.new(app).get("/") }

  describe ".before" do
    it do
      TreasureData::Logger::Agent::Rack::Hook.before do |env|
        dummy_object.called_at_before!(env)
      end
      expect(subject.status).to eq 200
      expect(dummy_object).to have_received(:called_at_before!).once
    end
  end

  describe ".after" do
    it do
      TreasureData::Logger::Agent::Rack::Hook.after do |env, result|
        dummy_object.called_at_after!
        result[0] = 201
      end
      expect(subject.status).to eq 201
      expect(dummy_object).to have_received(:called_at_after!).once
    end
  end
end
