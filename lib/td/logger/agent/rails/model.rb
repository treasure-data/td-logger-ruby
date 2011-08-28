module TreasureData
module Logger
module Agent
  module Rails

    def self.init_model
      ms = ModelMethods
      modms = ModelModuleMethods
      require 'active_record' unless defined?(ActiveRecord)
      ActiveRecord::Base.class_eval do
        include ms
        extend modms
      end
    end

    module ModelMethods
    end

    module ModelModuleMethods
      def td_enable_model_tracer(tag, options={})
        only = nil
        except = nil
        static = {}

        if o = options[:only]
          only = case o
            when Array
              o
            else
              [o]
            end.map {|e| e.to_s }
        end

        if o = options[:except]
          except = case o
            when Array
              o
            else
              [o]
            end.map {|e| e.to_s }
        end

        if o = options[:static]
          o.each_pair {|k,v|
            static[k.to_s] = v
          }
        end

        m = defined?(after_commit) ? :after_commit : :after_save

        __send__(m) do |record|
          m = {}
          record.attribute_names.each {|name|
            name = name.to_s
            if (!only || only.include?(name)) && (!except || !except.include?(name))
              m[name] = record.read_attribute(name)
            end
          }
          static.each_pair {|k,v|
            m[k] = v
          }
          if time = m['updated_at'] && time.is_a?(Time)
            m['time'] = time.to_i
            m.delete('updated_at')
          end
          TreasureData.log(tag, m)
        end
      end
    end
  end
end
end
end
