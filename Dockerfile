# syntax = docker/dockerfile:1

# Use smaller base image for faster pulls
FROM ghcr.io/clacky-ai/rails-base-template:latest AS base

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    NODE_ENV="production"

# Stage 1: Build dependencies (CACHED)
FROM base AS deps

WORKDIR /rails

# Install gems (cached layer)
COPY --chown=ruby:ruby Gemfile* ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install npm packages with production flag (faster)
COPY --chown=ruby:ruby package.json package-lock.json ./
RUN npm ci --production=false --legacy-peer-deps && \
    npm cache clean --force

# Stage 2: Build assets (FAST)
FROM base AS build

WORKDIR /rails

# Copy installed dependencies from previous stage
COPY --from=deps /usr/local/bundle /usr/local/bundle
COPY --from=deps /rails/node_modules /rails/node_modules

# Copy only what's needed for asset compilation
COPY --chown=ruby:ruby app/assets ./app/assets
COPY --chown=ruby:ruby app/javascript ./app/javascript
COPY --chown=ruby:ruby config ./config
COPY --chown=ruby:ruby bin ./bin
COPY --chown=ruby:ruby Rakefile ./
COPY --chown=ruby:ruby package.json ./
COPY --chown=ruby:ruby tailwind.config.js ./
COPY --chown=ruby:ruby postcss.config.js ./

# Precompile assets with dummy key (FAST - only CSS/JS)
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# Stage 3: Final runtime image (MINIMAL)
FROM base

WORKDIR /rails

# Copy built artifacts
COPY --from=deps /usr/local/bundle /usr/local/bundle
COPY --from=build /rails/public /rails/public

# Copy application code
COPY --chown=ruby:ruby . .

# Set runtime environment
ENV PATH="${PATH}:/home/ruby/.local/bin:/node_modules/.bin:/usr/local/bundle/bin" \
    USER="ruby" \
    PORT="3000"

# Entrypoint prepares database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE ${PORT}
CMD ["./bin/rails", "server"]
