FROM ruby:2.5

MAINTAINER Marten Veldthuis

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y git supervisor && \
    apt-get clean

WORKDIR /app
EXPOSE 80

ADD ./Gemfile /app
ADD ./Gemfile.lock /app
RUN bundle install --without development test

ADD ./ /app
ADD ./docker/supervisord.conf /etc/supervisor/conf.d/notifications.conf

ENTRYPOINT /app/docker/start.sh
