FROM marvambass/nginx-ssl-php
MAINTAINER MarvAmBass

ENV DH_SIZE 1024

RUN apt-get update; apt-get install -y \
    mysql-client \
    php5-mysql \
    php5-gd \
    php5-geoip \
    php-apc \
    curl \
    zip

# clean http directory
RUN rm -rf /usr/share/nginx/html/*

# install nginx piwik config
ADD nginx-piwik.conf /etc/nginx/conf.d/nginx-piwik.conf

# download piwik
RUN curl -O "http://builds.piwik.org/piwik.zip"

# unarchive piwik
RUN unzip piwik.zip

# add piwik config
ADD config.ini.php /piwik/config/config.ini.php

# add startup.sh
ADD startup-piwik.sh /opt/startup-piwik.sh
RUN chmod a+x /opt/startup-piwik.sh

# add '/opt/startup-piwik.sh' to entrypoint.sh
RUN sed -i 's/# exec CMD/# exec CMD\n\/opt\/startup-piwik.sh/g' /opt/entrypoint.sh
