FROM ubuntu:14.04.1
MAINTAINER ops@grnds.com
USER root

RUN sudo apt-get -y update && \
  sudo apt-get -y install curl wget

WORKDIR /root

RUN wget https://github.com/coreos/etcd/releases/download/v0.4.6/etcd-v0.4.6-linux-amd64.tar.gz -Oetcd.tar.gz && \
  tar zxvf etcd.tar.gz && \
  mv ./etcd-v0.4.6-linux-amd64/etcdctl /usr/bin/etcdctl && \
  rm -rfv ./etcd-v0.4.6-linux-amd64

COPY metrics.sh /root/metrics.sh

CMD /root/metrics.sh
