FROM nurelmdevelopment/ruby-base-image:stretch

RUN apt-get update && apt-get install -yq git

## help docker cache bundle
WORKDIR /tmp
ADD ./Gemfile /tmp/
ADD ./Gemfile.lock /tmp/

RUN bundle install

WORKDIR /app
ADD ./ /app

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
