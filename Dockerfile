FROM ruby:2.4.0
MAINTAINER "Hiroshi Yui" <hiroshi@ghostsinthelab.org>

ARG user
ARG uid

RUN useradd -m -u $uid $user
RUN mkdir /home/$user/fiidhub
WORKDIR /home/$user/fiidhub

COPY ./tmp/fiidhub.tar /tmp/fiidhub.tar
RUN tar xvf /tmp/fiidhub.tar
RUN mkdir tmp log
COPY ./config/config.yml config/config.yml
RUN bundle install

CMD ruby ./fiidhub.rb
