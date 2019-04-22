FROM nurelmdevelopment/ruby-base-image

RUN apt-get install -yq git

## help docker cache bundle
WORKDIR /tmp
ADD ./Gemfile /tmp/
ADD ./Gemfile.lock /tmp/

RUN bundle install
RUN rm -f /tmp/Gemfile /tmp/Gemfile.lock

WORKDIR /app
ADD ./ /app

EXPOSE 5000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
