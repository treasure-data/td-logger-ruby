module TreasureData
module Logger
module Agent::Rails
  module ControllerExtension

    def self.init
      mdl = self
      ActiveSupport.on_load :action_controller do
        ::ActionController::Base.send(:include, mdl)
      end
    end

    def self.included(mod)
      cm = ClassMethods
      mod.class_eval do
        extend cm
      end
    end

    def event
      TreasureData::Logger.event
    end

    module ClassMethods
    end

  end
end
end
end
