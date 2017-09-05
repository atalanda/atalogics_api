# ruby 2.2.7
FROM ruby@sha256:0e17f6457bd05197b7a431226a1030a17a3194e99c1770174a1472e191d364b2

WORKDIR /usr/src/app/
COPY . /usr/src/app/

RUN gem install bundler && bundle install
