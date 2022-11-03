FROM debian:bullseye as build-env

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y git gcc build-essential flex bison autoconf automake libtool libltdl3-dev liboping-dev pkg-config

RUN git clone --depth=1 --branch collectd-5.12.0 https://github.com/collectd/collectd.git 

ADD patches/0001-write-pings-to-stdout.patch collectd/0001-write-pings-to-stdout.patch
ADD patches/0002-stop-log-spam.patch collectd/0002-stop-log-spam.patch

RUN cd collectd && \
    git config --global user.name "Cloud Build" && \
    git config --global user.email "build@cloud.google.com" && \
    git am 0001-write-pings-to-stdout.patch && \
    git am 0002-stop-log-spam.patch

RUN cd collectd && \
    ./build.sh && \
    ./configure --prefix=/opt/collectd --enable-ping && \
    make && \
    make install

FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y liboping-dev

COPY --from=build-env /opt/collectd/ /opt/collectd/

ADD collectd.conf /etc/stackdriver/collectd.conf

CMD /opt/collectd/sbin/collectd -C /etc/stackdriver/collectd.conf -f
