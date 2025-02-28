# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  version_file = "lib/td/logger/version.rb"
  version = File.read("VERSION").strip
  File.open(version_file, "w") {|f|
    f.write <<EOF
module TreasureData
module Logger

VERSION = '#{version}'

end
end
EOF
  }

  gem.name        = %q{td-logger}
  gem.version     = version
  # gem.platform  = Gem::Platform::RUBY
  gem.authors     = ["Sadayuki Furuhashi"]
  #gem.email       = %q{frsyuki@gmail.com}
  #gem.homepage    = %q{https://github.com/treasure-data/td-logger-ruby}
  gem.description = %q{Treasure Data logging library}
  gem.summary     = gem.description
  gem.licenses    = ["Apache-2.0"]

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  gem.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile Rakefile .coveralls])
    end
  end
  gem.bindir = "exe"
  gem.executables = gem.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency "msgpack", ">= 0.5.6", "< 2.0"
  gem.add_dependency "td-client", ">= 0.8.66", "< 2.0"
  gem.add_dependency "fluent-logger", ">= 0.5.0", "< 2.0"
  gem.add_development_dependency 'rake', '>= 0.9.2'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'coveralls'
  ruby_version = Gem::Version.new(RUBY_VERSION)
  if ruby_version >= Gem::Version.new('2.2.2')
    gem.add_development_dependency 'rack'
  else
    gem.add_development_dependency 'rack', '~> 1.0'
  end
end
