FROM ubuntu:trusty
MAINTAINER Julian Reyes <jreyes@bix.com.uy>

ENV PHPMYADMIN_VERSION=5.1.1
ENV SUPERVISOR_VERSION=4.2.2

ENV PHP_VERSION=5.3

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install postfix python3-setuptools wget git apache2 php${PHP_VERSION}-xdebug libapache2-mod-php${PHP_VERSION} mysql-server php${PHP_VERSION}-mysql pwgen php${PHP_VERSION}-apcu php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring zip unzip php${PHP_VERSION}-zip curl php${PHP_VERSION}-curl && \
  apt-get -y autoremove && \
  apt-get -y clean && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf \

#RUN apt-get update && \
#  apt-get -y install supervisor git apache2 libapache2-mod-php5 mysql-server php5-mysql pwgen php-apc php5-mcrypt && \
#  echo "ServerName localhost" >> /etc/apache2/apache2.conf

ADD exim.debconf /root/
RUN debconf-set-selections < /root/exim.debconf && \
  apt-get install -y exim4

# Add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD start-exim4.sh /start-exim4.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD supervisord-exim4.conf /etc/supervisor/conf.d/supervisord-exim4.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# Add volumes for MySQL
VOLUME  ["/etc/mysql", "/var/lib/mysql", "/var/www/html" ]

# Add PhantomJS

RUN apt-get -y install libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev chrpath libssl-dev libxft-dev

# Add phpmyadmin
RUN wget -O /tmp/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
RUN tar -zxf /tmp/phpmyadmin.tar.gz -C /var/www
RUN ln -s /var/www/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /var/www/phpmyadmin
RUN mv /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php

# Add cumulusclips
RUN wget -O /tmp/cumulusclips.tar.gz http://cumulusclips.org/cumulusclips.tar.gz
RUN tar -zxf /tmp/cumulusclips.tar.gz -C /var/www

ENV PHANTOM_JS phantomjs-1.9.7-linux-x86_64
ADD ${PHANTOM_JS}.tar.bz2 /usr/local/share/
RUN ln -sf /usr/local/share/${PHANTOM_JS}/bin/phantomjs /usr/local/share/phantomjs
RUN ln -sf /usr/local/share/${PHANTOM_JS}/bin/phantomjs /usr/local/bin/phantomjs
RUN ln -sf /usr/local/share/${PHANTOM_JS}/bin/phantomjs /usr/bin/phantomjs
RUN phantomjs --version

EXPOSE 80 3306 25
CMD ["/run.sh"]
