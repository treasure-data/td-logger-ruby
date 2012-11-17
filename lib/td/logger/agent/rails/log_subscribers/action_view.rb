require 'active_support/log_subscriber'

module TreasureData
module Logger
module Agent::Rails
  class ViewLogSubscriber < ActiveSupport::LogSubscriber
    def render_template(event)
      message = "  Rendered #{from_rails_root(event.payload[:identifier])}"
      message << " within #{from_rails_root(event.payload[:layout])}" if event.payload[:layout]
      message << (" (%.1fms)" % event.duration)
      info(message)
    end
    alias :render_partial :render_template
    alias :render_collection :render_template

    # TODO: Ideally, ActionView should have its own logger so it does not depend on AC.logger
    def logger
      ActionController::Base.logger if defined?(ActionController::Base)
    end

  protected

    def from_rails_root(string)
      string.sub("#{Rails.root}/", "").sub(/^app\/views\//, "")
    end
  end

  ViewLogSubscriber.attach_to :action_view
end
end
end
