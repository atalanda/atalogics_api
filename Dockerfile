FROM ruby:3.2.1-bullseye

WORKDIR /usr/src/app/
COPY . /usr/src/app/

RUN gem install bundler && bundle install
