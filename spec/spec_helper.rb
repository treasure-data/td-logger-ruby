$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'td-logger'

RSpec.configure do |config|
  #config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec
end
