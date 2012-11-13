module TreasureData
module Logger
module Agent::Rails
  module ModelExtension

    def self.init
      # disable model extension ActiveRecord is not loaded
      # on Rails > 3 (other ORM is used)
      if !defined?(::ActiveRecord) &&
          ::Rails.respond_to?(:version) && ::Rails.version =~ /^3/
        return
      end
      require 'active_record'
      ::ActiveRecord::Base.send(:include, self)
    end

    def self.included(mod)
      cm = ClassMethods
      mod.class_eval do
        extend cm
      end
    end

    module ClassMethods
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

        if defined?(after_commit)
          # Rails 3
          m = :after_commit
        else
          # Rails 2
          m = :after_save
        end

        __send__(m) do |record|
          data = {}
          record.attribute_names.each {|name|
            name = name.to_s
            if (!only || only.include?(name)) && (!except || !except.include?(name))
              data[name] = record.read_attribute(name)
            end
          }
          static.each_pair {|k,v|
            data[k] = v
          }
          time = data['updated_at']
          if time.is_a?(Time)
            data.delete('updated_at')
          else
            time = Time.now
          end
          TreasureData::Logger.post_with_time(tag, data, time)
        end
      end
    end

  end
end
end
end
