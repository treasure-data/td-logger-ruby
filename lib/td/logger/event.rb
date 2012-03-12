module TreasureData
module Logger

  module EventPreset
    def action(name, record, uid=TD.event.attribute[:uid])
      unless uid
        raise ArgumentError, "wrong number of arguments (2 for 3): :uid attribute is required"
      end
      post(name, record.merge({:action=>name.to_s, :uid=>uid}))
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

  class Event
    def initialize
      @attribute = {}
    end

    attr_accessor :attribute

    def post(action, record={})
      TreasureData::Logger.post(action, @attribute.merge(record))
    end

    def post_with_time(action, record, time)
      TreasureData::Logger.post_with_time(action, @attribute.merge(record), time)
    end

    def self.use(mod)
      send(:include, mod)
    end
  end

  Event.use EventPreset

  def self.event
    Thread.current[:td_event] ||= Event.new
  end

end
end
