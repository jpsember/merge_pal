require 'rake'

Gem::Specification.new do |s|
  s.name        = 'merge_pal'
  s.version     = '0.0.0'
  s.date        = '2013-12-04'
  s.summary     = "Helps deal with git merge problems"
  s.description = "more to come"
  s.authors     = ["Jeff Sember"]
  s.email       = 'jpsember@gmail.com'
  s.files = FileList['lib/**/*.rb',
                      'bin/*',
                      '[A-Z]*',
                      'test/**/*',
                      ]
  s.executables << 'mergepal'
  s.add_runtime_dependency 'js_base'
  s.add_runtime_dependency 'backup_set'
  s.add_runtime_dependency 'git_repo'
  s.homepage = 'http://www.cs.ubc.ca/~jpsember'
  s.test_files  = Dir.glob('test/*.rb')
  s.license     = 'MIT'
end
