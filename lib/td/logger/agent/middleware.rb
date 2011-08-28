
module TreasureData
module Logger
module Agent


class Middleware
  @@before = []
  @@after = []

  def self.before(&block)
    @@before << block
  end

  def self.after(&block)
    @@after << block
  end

  def initialize(app, options={})
    @app = app
  end

  def call(env)
    @@before.each {|m|
      m.call(env)
    }

    result = @app.call(env)

    @@after.each {|m|
      m.call(env, result)
    }

    result
  end
end


end
end
end
