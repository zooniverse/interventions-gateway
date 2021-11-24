FROM ruby:2.6-slim

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y build-essential && \
    apt-get clean

WORKDIR /app

ADD ./Gemfile /app
ADD ./Gemfile.lock /app

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1` && \
  if echo "development test" | grep -w "$RACK_ENV"; then \
  bundle install ; \
  else bundle install --without development test; fi

ARG REVISION=''
ENV REVISION=$REVISION
ARG RACK_ENV=production
ENV RACK_ENV=$RACK_ENV

ADD ./ /app

EXPOSE 80
CMD ["/app/docker/start.sh"]
