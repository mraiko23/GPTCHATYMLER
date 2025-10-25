# GoodJob configuration
# GoodJob requires PostgreSQL, but this app uses JSON database
# GoodJob gem is only installed in development environment

if defined?(GoodJob) && Rails.env.development?
  # Development: GoodJob can use PostgreSQL
  Rails.application.configure do
    config.good_job.execution_mode = :async
    config.good_job.max_threads = 4
    config.good_job.poll_interval = 10
    config.good_job.shutdown_timeout = 25
    config.good_job.enable_cron = true
  end
else
  # Production: GoodJob not installed, use inline adapter
  Rails.application.configure do
    config.active_job.queue_adapter = :inline
  end
end
