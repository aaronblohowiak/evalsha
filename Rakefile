task :default => :test

task :test do
  require "cutest"

  Cutest.run(Dir["test/**/*.rb"])
end


desc "Deploy"
task :deploy do
  script = <<-EOS
  cd ~/redis-io
  git pull
  rvm 1.9.2 gem install dep --no-ri --no-rdoc
  (rvm 1.9.2 exec dep check || rvm 1.9.2 exec dep install)
  rvm 1.9.2 exec compass compile -c config/sass.rb views/styles.sass
  kill -s INT $(cat log/redis-io.pid)
  rvm 1.9.2 exec unicorn -D -c unicorn.rb -E production
  EOS

  sh "ssh redis-io '#{script.split("\n").map(&:strip).join(" && ")}'"
end
