FROM ruby:2
MAINTAINER ops@grandrounds.com
USER root
WORKDIR /root

RUN apt-get -qqq update && \
    apt-get install git

COPY Gemfile ./

RUN bundle install --gemfile=/root/Gemfile

RUN mkdir .ssh && chmod 700 .ssh
COPY ssh_config .ssh/config
RUN chmod 600 .ssh/config

COPY build.sh ./

ENV MOBILE_SPEC_BRANCH feature/2052890/103458506/mobile-specs-dockerfile

CMD ./build.sh
