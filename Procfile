web: bundle exec puma -C config/puma.rb
release: cp config/application.yml.production config/application.yml && cp config/database.yml.production config/database.yml && bundle exec rails db:migrate
