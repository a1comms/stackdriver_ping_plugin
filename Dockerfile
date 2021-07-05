FROM debian:8 as build-env

RUN apt-get update && \
    apt-get install -y git gcc build-essential flex bison autoconf automake libtool libltdl3-dev liboping-dev pkg-config

RUN git clone --depth=1 --branch 6.1.3 https://github.com/Stackdriver/collectd.git 

ADD patches/0001-write-pings-to-stdout.patch collectd/0001-write-pings-to-stdout.patch

RUN cd collectd && \
    git config --global user.name "Cloud Build" && \
    git config --global user.email "build@cloud.google.com" && \
    git am 0001-write-pings-to-stdout.patch

RUN cd collectd && \
    ./build.sh && \
    ./configure --enable-ping && \
    make

FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y liboping-dev curl gnupg

RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

RUN curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh && \
    bash add-monitoring-agent-repo.sh --also-install

ADD collectd.conf /etc/stackdriver/collectd.conf

COPY --from=build-env collectd/.libs/ping.so /opt/stackdriver/collectd/lib/x86_64-linux-gnu/collectd/

CMD /opt/stackdriver/collectd/sbin/stackdriver-collectd -C /etc/stackdriver/collectd.conf -f