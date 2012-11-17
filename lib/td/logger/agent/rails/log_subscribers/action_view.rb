require 'active_support/log_subscriber'
require 'td/logger/agent/rails/log_subscribers'

module TreasureData
module Logger
module Agent::Rails
  class ViewLogSubscriber < ActiveSupport::LogSubscriber
    AV_TABLE_NAME = 'view_actions'

    def render_template(event)
      payload = build_payload(event, 'render_template')
      LogSubscribersHelper::post(AV_TABLE_NAME, event.time, payload)
    end
    alias :render_partial :render_template
    alias :render_collection :render_template

    private

    def build_payload(event, subscribe)
      payload = LogSubscribersHelper::build_payload(event, subscribe)

      payload[:identifier] = from_rails_root(payload[:identifier])
      payload[:layout] = from_rails_root(payload[:layout]) if payload[:layout]

      payload
    end

    def from_rails_root(string)
      string.sub("#{Rails.root}/", "").sub(/^app\/views\//, "")
    end
  end

  ViewLogSubscriber.attach_to :action_view
end
end
end
