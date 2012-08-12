task :default => :test

task :test do
  require "cutest"

  Cutest.run(Dir["test/**/*.rb"])
end


task :style do
  `rvm 1.9.2@evalsha exec compass compile -c config/sass.rb sass/styles.sass`
end

desc "Deploy"
task :deploy do
  script = <<-EOS
  source .bash_login
  cd ~/evalsha
  git pull
  rvm gemset create evalsha
  rvm 1.9.2@evalsha gem install bundler
  rvm 1.9.2@evalsha exec bundle install
  rvm 1.9.2@evalsha exec compass compile -c config/sass.rb sass/styles.sass
  mkdir tmp
  touch tmp/restart.txt 
  EOS

  sh "ssh evalsha.com '#{script.split("\n").map(&:strip).join(" && ")}'"
end
