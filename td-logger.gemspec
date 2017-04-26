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

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
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
