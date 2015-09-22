FROM ubuntu:14.04
MAINTAINER ops@grnds.com
USER root

RUN apt-get update -qqq && apt-get install -qqq curl

WORKDIR /root
COPY pass-honesty.sh ./
CMD ./pass-honesty.sh
