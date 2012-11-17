require 'active_support/log_subscriber'
require 'td/logger/agent/rails/log_subscribers'

module TreasureData
module Logger
module Agent::Rails
  class ResourceLogSubscriber < ActiveSupport::LogSubscriber
    AR_TABLE_NAME = 'resource_actions'

    def request(event)
      payload = build_payload(event, 'request')
      LogSubscribersHelper::post(AR_TABLE_NAME, event.time, payload)
    end

    private

    def build_payload(event, subscribe)
      payload = LogSubscribersHelper::build_payload(event, subscribe)

      if result = payload.delete(:result)
        r = {}
        r[:code] = result.code
        r[:message] = result.message
        #r[:body] = result.body # too large?
        r[:body_size] = result.body.size
        payload[:result] = r
      end

      payload
    end
  end

  ResourceLogSubscriber.attach_to :active_resource
end
end
end
