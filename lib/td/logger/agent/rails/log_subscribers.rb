module TreasureData
module Logger
module Agent::Rails
  module LogSubscribersHelper
    module_function

    def self.post(table, time, payload)
      Rails.logger.info payload.to_json
      #TD.event.post_with_time(table, payload, time.to_i)
    end

    INTERNAL_PARAMS = %w(controller action format _method only_path)

    def build_payload(event, subscribe)
      payload = event.payload.clone

      if payload.has_key?(:params)
        params = payload.delete(:params).except(*INTERNAL_PARAMS)
        payload.merge!(params)
      end

      payload[:subscribe] = subscribe
      payload[:elapsed_time] = event.duration
      payload[:transaction_id] = event.transaction_id
      payload
    end
  end
end
end
end
