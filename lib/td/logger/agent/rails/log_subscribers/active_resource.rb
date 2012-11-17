require 'active_support/log_subscriber'

module TreasureData
module Logger
module Agent::Rails
  class ResourceLogSubscriber < ActiveSupport::LogSubscriber
    def request(event)
      result = event.payload[:result]
      info "#{event.payload[:method].to_s.upcase} #{event.payload[:request_uri]}"
      info "--> %d %s %d (%.1fms)" % [result.code, result.message, result.body.to_s.length, event.duration]
    end

    def logger
      ActiveResource::Base.logger
    end
  end

  ResourceLogSubscriber.attach_to :active_resource
end
end
end
