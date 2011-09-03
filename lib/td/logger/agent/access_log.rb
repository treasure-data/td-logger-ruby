
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

  ACCESS_LOG_PRESET_ENV_KEYS = {
    'ip'      => 'REMOTE_ADDR',
    'method'  => 'REQUEST_METHOD',
    'uri'     => 'REQUEST_URI',
    'referer' => 'HTTP_REFERER',
    'ua'      => 'HTTP_USER_AGENT'
  }

  def self.enable_access_log(tag)
    Middleware.before do |env|
      data = {}
      Thread.current['td.access_log'] = data
      env['td.access_log'] = data
    end

    Middleware.after do |env,result|
      data = env['td.access_log'] || {}

      ACCESS_LOG_PRESET_ENV_KEYS.each_pair {|key,val|
        data[key] ||= env[val] if env[val]
      }

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
