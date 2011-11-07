module TreasureData
module Logger

  module Event
    def self.use(mod)
      send(:include, mod)
    end
  end

  module EventPreset
    def action(name, record, uid=TD.event.attribute[:uid])
      unless uid
        raise ArgumentError, "wrong number of arguments (2 for 3): :uid attribute is required"
      end
      post(name, record.merge({:uid=>uid}))
    end

    def register(uid=TD.event.attribute[:uid])
      unless uid
        raise ArgumentError, "wrong number of arguments (0 for 1): :uid attribute is required"
      end
      action(:register, {}, uid)
    end

    def login(uid=TD.event.attribute[:uid])
      unless uid
        raise ArgumentError, "wrong number of arguments (0 for 1): :uid attribute is required"
      end
      action(:login, {}, uid)
    end

    def pay(category, sub_category, name, price, count, uid=TD.event.attribute[:uid])
      unless uid
        raise ArgumentError, "wrong number of arguments (3 for 4): :uid attribute is required"
      end
      action(:pay, {:category=>category, :sub_category=>sub_category, :name=>name, :price=>price, :count=>count}, uid)
    end
  end

  Event.use EventPreset

  class EventCollector
    def initialize
      @attribute = {}
    end

    attr_accessor :attribute

    def post(action, record={})
      TreasureData::Logger.post(action, @attribute.merge(record))
    end

    include Event
  end

  def self.event
    Thread.current[:td_event_collector] ||= EventCollector.new
  end

end
end
