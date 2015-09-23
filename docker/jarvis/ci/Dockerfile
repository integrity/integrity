FROM grnds/jarvis

RUN apt-get -y update && \
    apt-get -y install python-pip mysql-client phantomjs imagemagick wget jq facter && \
    pip install awscli

RUN wget https://saucelabs.com/downloads/sc-4.3.8-linux.tar.gz && \
   tar -xzf sc-4.3.8-linux.tar.gz sc-4.3.8-linux/bin/sc --strip-component=2 && \
   rm sc-4.3.8-linux.tar.gz && \
   mv sc /usr/local/bin/

RUN mkdir ~/.ssh && chmod 700 ~/.ssh
COPY ssh-config /root/.ssh/config

# facters
RUN mkdir -p /etc/facter/facts.d
COPY pancakes.sh /etc/facter/facts.d

CMD git clone --recursive https://$GITHUB_READ_TOKEN@github.com/consultingmd/consultingmd && ./consultingmd/honesty/git-checkout.sh
