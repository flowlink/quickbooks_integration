FROM ruby:2.7-alpine
MAINTAINER NuRelm <development@nurelm.com>

RUN apk add --no-cache --update build-base curl-dev git libcurl linux-headers openssl-dev ruby-dev sqlite-dev tzdata

WORKDIR /app
COPY ./ /app

RUN gem install bundler:1.16.0
RUN bundle install --jobs 5

RUN apk del build-base curl-dev git linux-headers openssl-dev ruby-dev

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
