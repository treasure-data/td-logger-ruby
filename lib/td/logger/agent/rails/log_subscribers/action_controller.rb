require 'active_support/core_ext/object/blank'
require 'active_support/log_subscriber'
require 'td/logger/agent/rails/log_subscribers'

module TreasureData
module Logger
module Agent::Rails
  class ControllerLogSubscriber < ActiveSupport::LogSubscriber
    AC_TABLE_NAME = 'controller_actions'

    def start_processing(event)
      payload = build_payload(event, 'start_processing')
      LogSubscribersHelper::post(AC_TABLE_NAME, event.time, payload)
    end

    def process_action(event)
      payload = build_payload(event, 'process_action')

      if !payload.has_key?(:status) && payload[:exception].present?
        exception, message = payload.delete(:exception)
        payload[:status] = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception)
        payload[:exception] = "#{exception}:#{message}"
      end

      LogSubscribersHelper::post(AC_TABLE_NAME, event.time, payload)
    end

    def send_file(event)
      payload = build_payload(event, 'send_file')
      LogSubscribersHelper::post(AC_TABLE_NAME, event.time, payload)
    end

    def redirect_to(event)
      # Store redirect location into TLS for getting in other actions
      Thread.current[:redirect_location] = event.payload[:location]
    end

    def send_data(event)
      payload = build_payload(event, 'send_data')
      LogSubscribersHelper::post(AC_TABLE_NAME, event.time, payload)
    end

    # Need?
    #def halted_callback(event)
    #  payload = build_payload(event, 'halted_callback')
    #  info "Filter chain halted as #{event.payload[:filter]} rendered or redirected"
    #end

    # Need cache related logs?
    #%w(write_fragment read_fragment exist_fragment?
    #   expire_fragment expire_page write_page).each do |method|
    #  class_eval <<-METHOD, __FILE__, __LINE__ + 1
    #    def #{method}(event)
    #      key_or_path = event.payload[:key] || event.payload[:path]
    #      human_name  = #{method.to_s.humanize.inspect}
    #      info("\#{human_name} \#{key_or_path} \#{"(%.1fms)" % event.duration}")
    #    end
    #  METHOD
    #end

    private

    def build_payload(event, subscribe)
      payload = LogSubscribersHelper::build_payload(event, subscribe)

      if redirect_location = Thread.current[:redirect_location]
        Thread.current[:redirect_location] = nil
        payload[:redirect_location] = redirect_location
      end

      payload
    end
  end

  ControllerLogSubscriber.attach_to :action_controller
end
end
end
