FROM ghcr.io/clacky-ai/rails-base-template:latest

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    NODE_ENV="production" \
    PATH="${PATH}:/home/ruby/.local/bin:/node_modules/.bin:/usr/local/bundle/bin" \
    USER="ruby" \
    PORT="3000"

WORKDIR /rails

# Install gems first (for caching)
COPY --chown=ruby:ruby Gemfile* ./
RUN bundle install

# Install npm packages (for caching)
COPY --chown=ruby:ruby package.json package-lock.json ./
RUN npm ci --legacy-peer-deps

# Copy application code
COPY --chown=ruby:ruby . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE ${PORT}
CMD ["./bin/rails", "server"]
