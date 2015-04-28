FROM gliderlabs/alpine:3.1
MAINTAINER ops@grnds.com

RUN apk --update add mysql-client bash py-pip groff less
RUN pip install awscli

WORKDIR /root
COPY ./freezer.sh ./

ENTRYPOINT ["/root/freezer.sh"]
