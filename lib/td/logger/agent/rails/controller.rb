module TreasureData
module Logger
module Agent::Rails
  module ControllerExtension

    def self.init
      ::ActionController::Base.send(:include, self)
    end

    if defined?(ActiveSupport::Concern)
      extend ActiveSupport::Concern
    else
      # Rails 2
      def self.included(mod)
        im = InstanceMethods
        cm = ClassMethods
        mod.class_eval do
          include im
          extend cm
        end
      end
    end

    module InstanceMethods
      def event
        TreasureData::Logger.event
      end
    end

    module ClassMethods
    end

  end
end
end
end
