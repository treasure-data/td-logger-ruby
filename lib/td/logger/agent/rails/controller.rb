module TreasureData
module Logger
module Agent
  module Rails

    def self.init_controller
      ActionController::Base.send(:include, ControllerExtension)
    end

    module ControllerExtension
      if defined?(ActiveSupport::Concern)
        # Rails 2
        extend ActiveSupport::Concern
      else
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
        def td_access_log
          request.env['td.access_log'] ||= {}
        end
      end

      module ClassMethods
      end
    end

  end
end
end
end
