FROM debian:unstable-slim

LABEL maintainer="inhere <zhanghongli@1bug.com>" version="2.0"

ARG timezone
ARG app_env=prod
ARG work_user=www-data

# default APP_ENV = test
ENV APP_ENV=${app_env:-"test"} \
    TIMEZONE=${timezone:-"Asia/Shanghai"}

RUN apt-get update && apt-get install -y \
    build-essential \
    libxml2-dev \
    libcurl4-openssl-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libwebp-dev \
    libxpm-dev \
    libssl-dev \
    libzip-dev \
    libonig-dev \
    libreadline-dev \
    vim \
    wget \
    curl \
    autoconf \
    apt-transport-https \
    ca-certificates \
    libsqlite3-dev \
    libxslt1-dev \
    libgd-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /d && cd /d && \
    wget https://www.php.net/distributions/php-8.3.13.tar.gz && \
    tar -xzf php-8.3.13.tar.gz && \
    cd php-8.3.13 && \
    ./configure --with-config-file-path=/usr/local/php \
                --enable-fpm \
                --with-pear \
                --enable-mbstring \
                --enable-soap \
                --with-curl \
                --with-openssl \
                --enable-intl \
                --with-mysqli \
                --with-xsl \
                --enable-pcntl \
                --with-bz2 \
                --enable-sockets \
                --with-zlib \
                --enable-sysvsem \
                --enable-sysvshm \
                --with-pdo-mysql \
                --enable-gd \
                --with-gd --with-jpeg --with-png \
                --with-fileinfo \
    && make && make install && \
    cp php.ini-development /usr/local/php/php.ini

Run php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://packagist.phpcomposer.com

RUN pecl channel-update pecl.php.net

RUN yes '' | pecl install redis \
     && echo "extension=redis.so" >> /usr/local/php/php.ini

# Install swoole extension
RUN yes '' | pecl install swoole \
    && echo "extension=swoole.so" >> /usr/local/php/php.ini

# Install yaconf extension
RUN yes '' | pecl install yaconf \
    && echo "extension=yaconf.so" >> /usr/local/php/php.ini \
    && echo yaconf.directory="/var/www/yaconf" >> /usr/local/php/php.ini \
    && echo yaconf.check_delay=0 >> /usr/local/php/php.ini

RUN yes '' | pecl install xlswriter \
    && echo "extension=xlswriter.so" >> /usr/local/php/php.ini

RUN echo "[global]" > /usr/local/etc/php-fpm.conf && \
    echo "error_log = /usr/local/etc/log" >> /usr/local/etc/php-fpm.conf && \
    echo "[www]" >> /usr/local/etc/php-fpm.conf && \
    echo "listen = 127.0.0.1:9000" >> /usr/local/etc/php-fpm.conf && \
    echo "user = www-data" >> /usr/local/etc/php-fpm.conf && \
    echo "group = www-data" >> /usr/local/etc/php-fpm.conf && \
    echo "pm = dynamic" >> /usr/local/etc/php-fpm.conf && \
    echo "pm.max_children = 150" >> /usr/local/etc/php-fpm.conf && \
    echo "pm.start_servers = 10" >> /usr/local/etc/php-fpm.conf && \
    echo "pm.min_spare_servers = 10" >> /usr/local/etc/php-fpm.conf && \
    echo "pm.max_spare_servers = 30" >> /usr/local/etc/php-fpm.conf

WORKDIR /var/www
EXPOSE 9000

CMD ["php-fpm", "-F", "-c", "/usr/local/php/php.ini"]