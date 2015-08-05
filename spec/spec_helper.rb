if defined?(:RUBY_ENGINE) && RUBY_ENGINE == 'ruby'
  # SimpleCov officially supports MRI 1.9+ only for now
  # https://github.com/colszowka/simplecov#ruby-version-compatibility

  require 'simplecov'
  unless ENV['APPVEYOR']
    require 'coveralls'

    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
  SimpleCov.start("test_frameworks")
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

REPO_ROOT = Pathname.new(File.expand_path("../", __FILE__))

require 'td-logger'

RSpec.configure do |config|
  #config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec
end
