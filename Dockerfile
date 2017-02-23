FROM ruby:2.4.0
MAINTAINER "Hiroshi Yui" <hiroshi@ghostsinthelab.org>

ARG user
ARG uid

RUN useradd -m -u $uid $user
RUN mkdir /home/$user/fiidhub
WORKDIR /home/$user/fiidhub

ADD ./tmp/fiidhub.tar .
COPY ./config/config.yml config/config.yml
RUN bundle install --without=development

CMD ruby ./fiidhub.rb
