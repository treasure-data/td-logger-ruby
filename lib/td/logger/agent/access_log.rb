
module TreasureData
module Logger
module Agent

  ACCESS_LOG_PARAM_ENV =
        if defined? Rails
          if Rails.respond_to?(:version) && Rails.version =~ /^3/
            # Rails 3
            'action_dispatch.request.path_parameters'
          else
            # Rails 2
            'action_controller.request.path_parameters'
          end
        else
          # Rack default
          'rack.routing_args'
        end

  ACCESS_LOG_PRESET_PARAM_KEYS = {
    'controller' => :controller,
    'action' => :action,
  }

  def self.enable_access_log(tag)
    Middleware.before do |env|
      data = {}
      Thread.current['td.access_log'] = data
      env['td.access_log'] = data
      env['td.access_time'] = Time.now
    end

    Middleware.after do |env,result|
      req = env['action_dispatch.request']
      if !req || !req.is_a?(Rack::Request)
        req = Rack::Request.new(env)
      end

      # ignore OPTIONS request
      if req.request_method != "OPTIONS"
        data = env['td.access_log'] || {}
        access_time = env['td.access_time']

        # add 'elapsed' column
        if access_time
          elapsed = Time.now - access_time
          data['elapsed'] = elapsed
          # set 'time' column to access time
          data['time'] = access_time
        end

        data['method'] ||= req.request_method
        data['ip'] ||= (env['action_dispatch.remote_ip'] || req.ip).to_s
        data['uri'] ||= env['REQUEST_URI'].to_s if env['REQUEST_URI']
        data['referer'] ||= env['HTTP_REFERER'].to_s if env['HTTP_REFERER']
        data['ua'] ||= env['HTTP_USER_AGENT'].to_s if env['HTTP_USER_AGENT']

        m = env[ACCESS_LOG_PARAM_ENV]
        ACCESS_LOG_PRESET_PARAM_KEYS.each_pair {|key,val|
          data[key] ||= m[val] if m[val]
        }

        # result code
        data['status'] ||= result[0].to_i

        TreasureData.log(tag, data)
      end
    end
  end

end
end
end
