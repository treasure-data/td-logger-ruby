module TreasureData
module Logger
module Agent
  module Rails

    def self.init_controller
      ms = ControllerMethods
      modms = ControllerModuleMethods
      ActionController::Base.class_eval do
        include ms
        extend modms
      end
    end

    module ControllerMethods
      def td_access_log
        request.env['td.access_log'] ||= {}
      end
    end

    module ControllerModuleMethods
    end

  end
end
end

def self.access_log
  Thread.current['td.access_log']
end

end
