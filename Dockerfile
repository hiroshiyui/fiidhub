FROM ruby:2.4.0
MAINTAINER "Hiroshi Yui" <hiroshi@ghostsinthelab.org>

RUN mkdir /fiidhub
WORKDIR /fiidhub

COPY ./tmp/fiidhub.tar /tmp/fiidhub.tar
RUN tar xvf /tmp/fiidhub.tar
RUN mkdir tmp log
COPY ./config/config.yml /fiidhub/config/config.yml
RUN bundle install

CMD ruby ./fiidhub.rb
