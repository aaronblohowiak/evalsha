task :default => :test

task :test do
  require "cutest"

  Cutest.run(Dir["test/**/*.rb"])
end


desc "Deploy"
task :deploy do
  script = <<-EOS
  cd ~/evalsha
  git pull
  rvm gemset create evalsha
  rvm 1.9.2@evalsha gem install bundler
  rvm 1.9.2@evalsha exec bundle install
  rvm 1.9.2@evalsha exec compass compile -c config/sass.rb sass/styles.sass
  EOS

  sh "ssh evalsha.com '#{script.split("\n").map(&:strip).join(" && ")}'"
end
