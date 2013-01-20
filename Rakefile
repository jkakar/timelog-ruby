require 'yard'

desc 'Generate API documentation'
YARD::Rake::YardocTask.new

desc 'Run the tests'
task :test do
  sh 'bundle exec turn -I test -I lib test'
end
