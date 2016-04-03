# workers Integer(ENV['WEB_CONCURRENCY'] || 2)      # Processes to run concurrent requests
threads_count = Integer(ENV['MAX_THREADS'] || 5)  # Threads to run concurrent requests
threads threads_count, threads_count              # Min and max threads count can be the same on Heroku

preload_app!                                      # Preloading the application reduces the startup time of individual Puma worker processes

rackup      DefaultRackup                         # Tell Puma how to start your rack app.
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'      # On Heroku ENV['RACK_ENV'] will be set to 'production' by default

# on_worker_boot do
#   # Worker specific setup for Rails 4.1+
#   # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
#   ActiveRecord::Base.establish_connection
# end