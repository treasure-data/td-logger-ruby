
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

        # 'elapsed' column
        if access_time = env['td.access_time']
          unless record.has_key?(:elapsed)
            record[:elapsed] = Time.now - access_time
          end

          # always overwrite 'time' column by access time
          record[:time] = access_time
        end

        # merge params
        req.params.each_pair {|key,val|
          key = key.to_sym
          unless record.has_key?(key)
            record[key] = val
          end
        }

        # 'method' column
        if !record.has_key?(:method)
          record[:method] = req.request_method
        end

        # 'ip' column
        unless record.has_key?(:ip)
          record[:ip] = (env['action_dispatch.remote_ip'] || req.ip).to_s
        end

        # 'path' column
        #   requested path before '?'
        unless record.has_key?(:path)
          if path = env['REQUEST_URI']
            if m = /(?:\w{1,10}\:\/\/[^\/]+)?([^\?]*)/.match(path)
              record[:path] = m[1]
            end
          end
        end

        # 'host' column
        #   Rack#host_with_port consideres HTTP_X_FORWARDED_HOST
        unless record.has_key?(:host)
          record[:host] = req.host_with_port
        end

        # 'referer' column
        unless record.has_key?(:referer)
          if referer = env['HTTP_REFERER']
            record[:referer] = referer.to_s
          end
        end

        # 'agent' column
        unless record.has_key?(:agent)
          if agent = env['HTTP_USER_AGENT']
            record[:agent] = agent
          end
        end

        # 'status' column
        unless record.has_key?(:status)
          record[:status] = result[0].to_i
        end

        # 'controller' and 'action' columns
        if m = env[ACCESS_LOG_PARAM_ENV]
          ACCESS_LOG_PRESET_PARAM_KEYS.each_pair {|key,val|
            unless record.has_key?(key)
              record[key] = m[val] if m[val]
            end
          }
        end

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
