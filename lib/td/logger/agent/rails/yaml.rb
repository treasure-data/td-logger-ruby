require 'yaml'

unless YAML.respond_to?(:unsafe_load)
  # Ruby < 2.6
  class << YAML
    alias unsafe_load load
  end
end
