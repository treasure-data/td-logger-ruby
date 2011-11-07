require 'rake'
require 'rake/testtask'
require 'rake/clean'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "td-logger"
    gemspec.summary = "Treasure Data logging library for Rails"
    gemspec.authors = ["Sadayuki Furuhashi"]
    #gemspec.email = "frsyuki@users.sourceforge.jp"
    #gemspec.homepage = "http://example.com/"
    gemspec.has_rdoc = false
    gemspec.require_paths = ["lib"]
    gemspec.add_dependency "msgpack", "~> 0.4.4"
    gemspec.add_dependency "td-client", "~> 0.8.0"
    gemspec.add_dependency "fluent-logger", "~> 0.4.1"
    gemspec.test_files = Dir["test/**/*.rt"]
    gemspec.files = Dir["lib/**/*", "ext/**/*", "test/**/*.rb", "test/**/*.rt"]
    gemspec.executables = []
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

VERSION_FILE = "lib/td/logger/version.rb"

file VERSION_FILE => ["VERSION"] do |t|
  version = File.read("VERSION").strip
  File.open(VERSION_FILE, "w") {|f|
    f.write <<EOF
module TreasureData
module Logger

VERSION = '#{version}'

end
end
EOF
  }
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => [VERSION_FILE, :build]

