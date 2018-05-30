# ruby 2.2.7
FROM ruby:2.4.3-stretch

WORKDIR /usr/src/app/
COPY . /usr/src/app/

RUN gem install bundler && bundle install
