FROM ubuntu:20.04
MAINTAINER Mark mark@douwantech.com

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    make \
    gcc \
    g++ \
    automake \
    libtool \
    mysql-client \
    libmysqlclient-dev \
    libxml2-dev \
    libexpat1-dev \
    python3-dev

RUN mkdir -p /usr/src/coreseek
ADD ./coreseek /usr/src/coreseek
RUN chmod 755 -R /usr/src/coreseek

WORKDIR /usr/src/coreseek/mmseg-3.2.14
RUN ./bootstrap
RUN ./configure
RUN make -C src libmmseg.la -j $(nproc) && make && make install

WORKDIR /usr/src/coreseek/csft-4.1
RUN ./buildconf.sh
RUN ./configure --without-unixodbc --with-mmseg --with-mysql
RUN make -j $(nproc) && make install
RUN strip /usr/local/bin/*

FROM ubuntu:20.04
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libmysqlclient-dev \
    libexpat1-dev \
    cron && rm -rf /var/lib/apt/lists/*
COPY --from=0 /usr/local/bin /usr/local/bin
COPY --from=0 /usr/local/etc /usr/local/etc
ADD ./cron/sphinx /etc/cron.hourly/sphinx

VOLUME ["/usr/local/etc/sphinx", "/var/log/sphinx"]

RUN ln -s /usr/local/etc/sphinx/sphinx.conf /usr/local/etc/csft.conf
RUN mkdir -p /var/sphinx/log/
RUN mkdir -p /var/sphinx/data/

WORKDIR /

EXPOSE 9312


ADD ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
