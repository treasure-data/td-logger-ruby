module TreasureData
module Logger
module Agent::Rails
  module ControllerExtension

    def self.init
      ::ActionController::Base.send(:include, self)
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
