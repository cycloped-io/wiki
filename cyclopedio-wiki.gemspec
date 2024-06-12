# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cyclopedio/wiki/version"

Gem::Specification.new do |s|
  s.name        = "cyclopedio-wiki"
  s.version     = Cyclopedio::Wiki::VERSION
  s.authors     = ["Aleksander Smywinski-Pohl","Krzysztof Wrobel"]
  s.email       = ["apohllo@o2.pl"]
  s.homepage    = "http://cycloped.io"
  s.summary     = %q{Database for storing Wikipedia data with very fast access}
  s.description = %q{Ruby Object Database with data extracted from Wikipedia, allowing for fast and easy access}

  s.rubyforge_project = "cyclopedio-wiki"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('rod', '~> 0.7.4.0')
end
