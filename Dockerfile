FROM ruby:2.5.7

ARG BUNDLE_GEMS__CONTRIBSYS__COM
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY square_primary_certificate_authority_g2.crt /usr/local/share/ca-certificates/
COPY square_service_authority_g2.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
RUN apt-get update -qq \
    && apt-get install -y build-essential nodejs libarchive-dev libpq-dev \
       postgresql-client cmake tidy git \
    && apt-get clean

COPY Gemfile* $APP_HOME/
RUN gem update --system
RUN gem install bundler:1.17.3

COPY . $APP_HOME
RUN gem install /app/vendor/sidekiq-pro-3.4.5.gem
RUN bundle install
