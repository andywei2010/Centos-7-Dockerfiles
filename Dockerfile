FROM centos:centos7
MAINTAINER Andy wei <andywei2010@163.com>

RUN yum -y update; yum clean all
RUN yum -y install gcc \
        pcre-devel \
        openssl openssl-devel \
        gperftools-devel \
        tar \
        openssh-server; yum clean all

# 创建用户
RUN echo "root:root@dev" | chpasswd
RUN useradd -m webserver
RUN echo "webserver:webserver@dev" | chpasswd
RUN echo "webserver ALL=(ALL) ALL" >> /etc/sudoers

# 创建 ssh 远程登录
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN sed -ri 's/session required pam_loginuid.so/#session required pam_loginuid.so/g' /etc/pam.d/sshd
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -P "" -t rsa -f /etc/ssh/ssh_host_rsa_key

# 安装 supervisord 守护进程
RUN yum -y install python-setuptools; yum clean all
RUN easy_install supervisor
RUN mkdir -p /usr/local/var/log/supervisord
COPY supervisord.conf /etc/supervisord.conf

# 安装 nginx
RUN mkdir -p /home/soft
RUN mkdir -p /usr/local/opt/nginx/1.10.2
RUN mkdir -p /usr/local/etc/nginx
RUN mkdir -p /usr/local/var/log/nginx
RUN mkdir -p /usr/local/var/run
RUN mkdir -p /usr/local/var/run/nginx/client_body_temp
RUN mkdir -p /usr/local/var/run/nginx/proxy_temp
RUN mkdir -p /usr/local/var/run/nginx/fastcgi_temp
RUN mkdir -p /usr/local/var/run/nginx/uwsgi_temp
RUN mkdir -p /usr/local/var/run/nginx/scgi_temp
RUN mkdir -p /home/webserver/www

COPY nginx/nginx-1.10.2.tar.gz /home/soft/
RUN cd /home/soft && tar xf nginx-1.10.2.tar.gz && cd nginx-1.10.2 && ./configure --prefix=/usr/local/opt/nginx/1.10.2 \
        --user=webserver \
        --group=webserver \
        --with-http_ssl_module \
        --with-pcre \
        --with-ipv6 \
        --sbin-path=/usr/local/opt/nginx/1.10.2/bin/nginx \
        --conf-path=/usr/local/etc/nginx/nginx.conf \
        --pid-path=/usr/local/var/run/nginx.pid \
        --lock-path=/usr/local/var/run/nginx.lock \
        --http-client-body-temp-path=/usr/local/var/run/nginx/client_body_temp \
        --http-proxy-temp-path=/usr/local/var/run/nginx/proxy_temp \
        --http-fastcgi-temp-path=/usr/local/var/run/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/usr/local/var/run/nginx/uwsgi_temp \
        --http-scgi-temp-path=/usr/local/var/run/nginx/scgi_temp \
        --http-log-path=/usr/local/var/log/nginx/access.log \
        --error-log-path=/usr/local/var/log/nginx/error.log \
        --with-http_gzip_static_module \
        --with-http_flv_module \
        --with-http_mp4_module && make && make install

RUN ln -s /usr/local/opt/nginx/1.10.2/bin/nginx /etc/init.d/nginx
RUN ln -s /usr/local/opt/nginx/1.10.2/bin/nginx /usr/local/bin/nginx

COPY nginx/conf.d/development/ /usr/local/etc/nginx

RUN echo "<?php phpinfo(); ?>" > /usr/local/opt/nginx/1.10.2/html/index.php
RUN chmod u+x /etc/init.d/nginx

RUN chown -R webserver:webserver /etc/init.d/nginx \
        /usr/local/opt/nginx \
        /usr/local/etc/nginx \
        /usr/local/var/log/nginx \
        /usr/local/var/run \
        /usr/local/bin/nginx \
        /home/webserver/www

# 安装 php 以及扩展
COPY php/php-7.1.0.tar.gz /home/soft/
COPY php/redis-3.1.0.tgz /home/soft/
COPY php/mongodb-1.2.8.tgz /home/soft/
COPY php/libmemcached-1.0.18.tar.gz /home/soft/
COPY php/memcached-3.0.3 /home/soft/memcached-3.0.3
#COPY php/imagick-3.4.3RC1.tgz /home/soft/

RUN yum install -y libxml2 libxml2-devel \
        bzip2 bzip2-devel \
        libcurl libcurl-devel \
        libjpeg libjpeg-devel libpng libpng-devel \
        freetype freetype-devel \
        gmp gmp-devel \
        readline readline-devel \
        libxslt libxslt-devel \
        autoconf \
        zlib zlib-devel \
        libicu-devel \
        gcc-c++; yum clean all

RUN mkdir -p /usr/local/opt/php/7.1.0
RUN mkdir -p /usr/local/opt/php/7.1.0/share/man
RUN mkdir -p /usr/local/opt/php/7.1.0/libexec
RUN mkdir -p /usr/local/opt/freetype
RUN mkdir -p /usr/local/opt/gettext
RUN mkdir -p /usr/local/opt/jpeg
RUN mkdir -p /usr/local/opt/libpng
RUN mkdir -p /usr/local/etc/php/7.1
RUN mkdir -p /usr/local/etc/php/7.1/conf.d


RUN cd /home/soft && tar xf php-7.1.0.tar.gz && cd php-7.1.0 && ./configure --prefix=/usr/local/opt/php/7.1.0 \
        --localstatedir=/usr/local/var \
        --sysconfdir=/usr/local/etc/php/7.1 \
        --with-config-file-path=/usr/local/etc/php/7.1 \
        --with-config-file-scan-dir=/usr/local/etc/php/7.1/conf.d \
        --mandir=/usr/local/opt/php/7.1.0/share/man \
        --enable-bcmath \
        --enable-calendar \
        --enable-dba \
        --enable-exif \
        --enable-ftp \
        --enable-gd-native-ttf \
        --enable-intl \
        --enable-mbregex \
        --enable-mbstring \
        --enable-shmop \
        --enable-soap \
        --enable-sockets \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-wddx \
        --enable-zip \
        --with-freetype-dir=/usr/local/opt/freetype \
        --with-gd \
        --with-gettext=/usr/local/opt/gettext \
        --with-iconv-dir=/usr \
        --with-jpeg-dir=/usr/local/opt/jpeg \
        --with-mhash \
        --with-openssl \
        --with-png-dir=/usr/local/opt/libpng \
        --with-xmlrpc \
        --libexecdir=/usr/local/opt/php/7.1.0/libexec \
        --with-bz2=/usr \
        --disable-debug \
        --enable-fpm \
        --with-fpm-user=webserver \
        --with-fpm-group=webserver \
        --with-curl \
        --with-xsl=/usr \
        --with-mysql-sock=/tmp/mysql.sock \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --disable-opcache \
        --enable-pcntl \
        --disable-phpdbg \
        --enable-maintainer-zts \
        --with-zlib=/usr \
        --with-zlib-dir=/usr \
        --with-libxml-dir && make && make install

RUN ln -s /usr/local/opt/php/7.1.0/sbin/php-fpm /etc/init.d/php-fpm
RUN ln -s /usr/local/opt/php/7.1.0/sbin/php-fpm /usr/local/bin/php-fpm
RUN ln -s /usr/local/opt/php/7.1.0/bin/php /usr/local/bin/php

RUN chmod u+x /etc/init.d/php-fpm

RUN cp /usr/local/etc/php/7.1/php-fpm.d/www.conf.default /usr/local/etc/php/7.1/php-fpm.d/www.conf
RUN cp /usr/local/etc/php/7.1/php-fpm.conf.default /usr/local/etc/php/7.1/php-fpm.conf
RUN cp /home/soft/php-7.1.0/php.ini-development /usr/local/etc/php/7.1/php.ini

RUN sed -ri 's/;date.timezone =/date.timezone = PRC/g' /usr/local/etc/php/7.1/php.ini
RUN sed -ri 's/post_max_size = 8M/post_max_size = 20M/g' /usr/local/etc/php/7.1/php.ini

# 安装 memcached
RUN cd /home/soft && tar xf libmemcached-1.0.18.tar.gz && cd libmemcached-1.0.18 && ./configure --prefix=/usr/local/libmemcached \
        --with-libmemcached-dir=/usr/local/libmemcached && make && make install
RUN cd /home/soft/memcached-3.0.3 && /usr/local/opt/php/7.1.0/bin/phpize && ./configure --with-php-config=/usr/local/opt/php/7.1.0/bin/php-config \
        --with-libmemcached-dir=/usr/local/libmemcached \ 
        --disable-memcached-sasl && make && make install
RUN echo -e "[memcached]\nextension=\"memcached.so\"" > /usr/local/etc/php/7.1/conf.d/ext-memcached.ini

# 安装 redis
RUN cd /home/soft && tar xf redis-3.1.0.tgz && cd redis-3.1.0 && /usr/local/opt/php/7.1.0/bin/phpize && ./configure --with-php-config=/usr/local/opt/php/7.1.0/bin/php-config && make && make install
RUN echo -e "[redis]\nextension=\"redis.so\"" > /usr/local/etc/php/7.1/conf.d/ext-redis.ini

# 安装 mongodb
RUN cd /home/soft && tar xf mongodb-1.2.8.tgz && cd mongodb-1.2.8 && /usr/local/opt/php/7.1.0/bin/phpize && ./configure --with-php-config=/usr/local/opt/php/7.1.0/bin/php-config && make && make install
RUN echo -e "[mongodb]\nextension=\"mongodb.so\"" > /usr/local/etc/php/7.1/conf.d/ext-mongodb.ini

# 安装 imagick
#RUN yum install -y ImageMagick-devel; yum clean all
#RUN cd /home/soft && tar xf imagick-3.4.3RC1.tgz && cd imagick-3.4.3RC1 && /usr/local/opt/php/7.1.0/bin/phpize && ./configure --with-php-config=/usr/local/opt/php/7.1.0/bin/php-config && make && make install
#RUN echo -e "[imagick]\nextension=\"imagick.so\"" > /usr/local/etc/php/7.1/conf.d/ext-imagick.ini

RUN chown -R webserver:webserver /usr/local/opt/php \
        /usr/local/opt/freetype \
        /usr/local/opt/gettext \
        /usr/local/opt/jpeg \
        /usr/local/opt/libpng \
        /usr/local/etc/php \
        /etc/init.d/php-fpm \
        /usr/local/bin/php-fpm \
        /usr/local/bin/php


#RUN rm -rf /home/soft

EXPOSE 80 22

CMD ["/usr/bin/supervisord","-c", "/etc/supervisord.conf"]
