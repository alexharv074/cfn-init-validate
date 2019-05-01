require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

desc 'Generate docs'
task :docs do
  require 'erb'
  i = '.README.erb'
  o = 'README.md'
  template = File.read(i)
  renderer = ERB.new(template, nil, '-')
  File.write(o, renderer.result())
end

