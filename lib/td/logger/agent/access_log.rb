
module TreasureData
module Logger
module Agent

  ACCESS_LOG_PARAM_ENV =
        if defined? ::Rails
          if ::Rails.respond_to?(:version) && ::Rails.version =~ /^3/
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
    :controller => :controller,
    :action => :action,
  }

  def self.enable_access_log(config)
    tag = config.access_log_table

    Middleware.before do |env|
      record = {}
      Thread.current['td.access_log'] = record
      env['td.access_log'] = record
      env['td.access_time'] = Time.now
    end

    Middleware.after do |env,result|
      req = env['action_dispatch.request']
      if !req || !req.is_a?(Rack::Request)
        req = Rack::Request.new(env)
      end

      # ignore OPTIONS request
      if req.request_method != "OPTIONS"
        record = env['td.access_log'] || {}
        access_time = env['td.access_time']

        # 'elapsed' column
        if access_time
          elapsed = Time.now - access_time
          record[:elapsed] = elapsed
          # set 'time' column to access time
          record[:time] = access_time
        end

        # 'method' column
        record[:method] ||= req.request_method

        # 'ip' column
        record[:ip] ||= (env['action_dispatch.remote_ip'] || req.ip).to_s

        # 'path' column
        #   REQUEST_URI before '?'
        unless record[:path]
          if path = env['REQUEST_URI']
            path = path.to_s.sub(/\?.*$/,'')
            record[:path] = path
          end
        end

        # 'host' column
        #   Rack#host_with_port consideres HTTP_X_FORWARDED_HOST
        record[:host] = request.host_with_port

        # 'referer' column
        record[:referer] ||= env['HTTP_REFERER'].to_s if env['HTTP_REFERER']

        # 'ua' column
        record[:ua] ||= env['HTTP_USER_AGENT'].to_s if env['HTTP_USER_AGENT']

        # merge params
        m = env[ACCESS_LOG_PARAM_ENV]
        ACCESS_LOG_PRESET_PARAM_KEYS.each_pair {|key,val|
          record[key] ||= m[val] if m[val]
        }

        # result code
        record[:status] ||= result[0].to_i

        TreasureData.log(tag, record)
      end
    end
  end

end
end
end

module TreasureData
  def self.access_log
    Thread.current['td.access_log']
  end
end
