FROM ubuntu:14.04.1
MAINTAINER ops@grnds.com
USER root
# Base grnds/jarvis

ADD chris-lea-node_js-trusty.list /etc/apt/sources.list.d/
RUN add-apt-repository ppa:chris-lea/node.js
RUN gpg -q --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 # rvm
RUN apt-get -qqq update
RUN apt-get install -y git git-core curl libmysqlclient-dev nodejs libxml2-dev libpq-dev
RUN \curl -sSL https://get.rvm.io | bash -s stable

WORKDIR /root
ADD upstart-envs /root/
RUN /bin/bash -l -c 'rvm install `grep export\ RUBYVERSION upstart-envs | cut -d= -f2`'
