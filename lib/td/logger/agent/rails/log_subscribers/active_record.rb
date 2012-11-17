require 'active_support/log_subscriber'
require 'td/logger/agent/rails/log_subscribers'

module TreasureData
module Logger
module Agent::Rails
  class RecordLogSubscriber < ActiveSupport::LogSubscriber
    AR_TABLE_NAME = 'record_actions'

    def sql(event)
      payload = LogSubscribersHelper::build_payload(event, 'sql')
      payload[:sql] = payload[:sql].squeeze(' ')
      LogSubscribersHelper::post(AR_TABLE_NAME, event.time, payload)
    end

    def identity(event)
      # When does this event fire?
      payload = LogSubscribersHelper::build_payload(event, 'identity')
      LogSubscribersHelper::post(AR_TABLE_NAME, event.time, payload)
    end
  end

  RecordLogSubscriber.attach_to :active_record
end
end
end
