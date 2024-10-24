FROM php:8.3-fpm

LABEL maintainer="inhere <zhanghongli@1bug.com>" version="2.0"

# --build-arg timezone=Asia/Shanghai
ARG timezone
# app env: prod pre test dev
ARG app_env=test
# default use www-data user
ARG work_user=www-data

# default APP_ENV = test
ENV APP_ENV=${app_env:-"test"} \
    TIMEZONE=${timezone:-"Asia/Shanghai"}

# 清理旧的源文件
RUN rm -f /etc/apt/sources.list.d/*

# 设置新的源
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list \
    && echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list \
    && echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list

# 清理缓存并更新包列表
RUN apt-get clean \
    && apt-get update

# 升级系统包
RUN apt-get dist-upgrade -y



# 安装基本工具
RUN apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    git \
    zip \
    openssl

# 安装 libcurl 和 libpq 相关库
RUN apt-get remove --purge -y libcurl4
RUN apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libpq-dev

# 安装 SSL 相关库
RUN apt-get install -y --no-install-recommends \
    libssl-dev

# 安装 Brotli 库
RUN apt-get install -y --no-install-recommends --allow-downgrades \
    libbrotli1=1.0.9-2+b2 \
    libbrotli-dev

# 安装 Ares 和图像处理库
RUN apt-get install -y --no-install-recommends \
    libc-ares-dev

RUN apt-get install -y --no-install-recommends libjpeg-dev

# 检查并移除 zlib1g
RUN apt-get remove --purge -y zlib1g || true

RUN apt-get install -y --no-install-recommends --allow-downgrades zlib1g=1:1.2.11.dfsg-2+deb11u2

RUN apt-get install -y --no-install-recommends \
    libpng-dev

RUN apt-get install -y --no-install-recommends \
    libfreetype6-dev

# 安装特定版本的 zlib1g
RUN apt-get install -y --no-install-recommends zlib1g-dev

RUN rm -rf /var/lib/apt/lists/*

# 清理 apt 缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

RUN docker-php-ext-install bcmath pdo_mysql mysqli sockets sysvmsg sysvsem sysvshm

Run php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://packagist.phpcomposer.com

RUN yes '' | pecl install redis \
    && docker-php-ext-enable redis

# Install swoole extension
RUN pecl install -D 'enable-sockets="no" enable-openssl="yes" enable-http2="yes" enable-mysqlnd="yes" enable-swoole-json="no" enable-swoole-curl="yes" enable-cares="yes" enable-brotli="yes" enable-swoole-pgsql="no" with-swoole-odbc="no" with-swoole-oracle="no" enable-swoole-sqlite="no"' swoole \
    && docker-php-ext-enable swoole

# Install yaconf extension
RUN pecl install yaconf \
    && docker-php-ext-enable yaconf \
    && echo yaconf.directory="/var/www/yaconf" >> /usr/local/etc/php/conf.d/yaconf.ini \
    && echo yaconf.check_delay=0 >> /usr/local/etc/php/conf.d/yaconf.ini

RUN yes '' | pecl install xlswriter \
    && docker-php-ext-enable xlswriter

# base.ini
RUN echo file_uploads=On >> /usr/local/etc/php/conf.d/base.ini \
    && echo memory_limit=2048M >> /usr/local/etc/php/conf.d/base.ini \
    && echo upload_max_filesize=512M >> /usr/local/etc/php/conf.d/base.ini \
    && echo post_max_size=512M >> /usr/local/etc/php/conf.d/base.ini \
    && echo max_execution_time=7200 >> /usr/local/etc/php/conf.d/base.ini

RUN apt-get clean \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

ADD . /var/www

WORKDIR /var/www
EXPOSE 9000

# ENTRYPOINT ["php", "/var/www", "http:start"]
#CMD ["php", "/var/www", "http:start"]