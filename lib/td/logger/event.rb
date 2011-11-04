module TreasureData
module Logger

  module Event
    def self.use(mod)
      send(:include, mod)
    end
  end

  module EventPreset
    def action(name, record, uid=TD.attribute[:uid])
      unless uid
        raise ArgumentError, "wrong number of arguments (2 for 3): uid is required"
      end
      post(:login, record.merge({:uid=>uid}))
    end

    def register(uid=TD.attribute[:uid])
      action(:register, {}, uid)
    end

    def login(uid=TD.attribute[:uid])
      action(:register, {}, uid)
    end

    def pay(category, sub_category, item, uid=TD.attribute[:uid])
      action(:pay, {:category=>category, :sub_category=>sub_category, :item=>item}, uid)
    end
  end

  Event.use EventPreset

  class EventCollector
    def initialize
      @attribute = {}
    end

    attr_accessor :attribute

    def post(action, record, time=Time.now)
      TreasureData::Logger.post(action, @attribute.merge(record), time)
    end

    include Event
  end

  def self.event
    Thread.current[:td_event_collector] ||= EventCollector.new
  end

end
end
