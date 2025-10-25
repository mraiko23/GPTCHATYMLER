# Puma configuration file

# Set the number of worker threads (Railway recommends 5)
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000
# Railway automatically sets the PORT environment variable
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in
environment ENV.fetch("RAILS_ENV", "development")

# Specifies the number of `workers` to boot in clustered mode
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`
# Railway free tier works best with 0-2 workers
workers ENV.fetch("WEB_CONCURRENCY", 2)

# Use the `preload_app!` method when specifying a `workers` number
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory
preload_app!

# Allow puma to be restarted by `bin/rails restart` command
plugin :tmp_restart

# Specify the PID file location
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid") if ENV["PIDFILE"]

# Bind to 0.0.0.0 to accept connections from any IP (required for Railway)
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 3000)}"

# Set the log file location
stdout_redirect ENV.fetch("PUMA_STDOUT", "log/puma_stdout.log"), 
                ENV.fetch("PUMA_STDERR", "log/puma_stderr.log"), 
                true if ENV["PUMA_STDOUT"]

# Configure worker lifecycle
on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

before_fork do
  # Disconnect from the database before forking
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end
