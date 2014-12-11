FROM marvambass/nginx-ssl-php
MAINTAINER MarvAmBass

ENV DH_SIZE 512

RUN apt-get update && apt-get install -y \
    mysql-client \
    php5-mysql \
    php5-gd \
    php5-geoip \
    php-apc \
    wget

# clean http directory
RUN rm -rf /usr/share/nginx/html/*

# install nginx piwik config
ADD nginx-piwik.conf /etc/nginx/conf.d/nginx-piwik.conf

RUN wget -qO- "http://builds.piwik.org/piwik-latest.tar.gz" | tar xz 

# add piwik config
ADD config.ini.php /piwik/config/config.ini.php

# add startup.sh
ADD startup-piwik.sh /opt/startup-piwik.sh
RUN chmod a+x /opt/startup-piwik.sh

# add '/opt/startup-piwik.sh' to entrypoint.sh
RUN sed -i 's/# exec CMD/# exec CMD\n\/opt\/startup-piwik.sh/g' /opt/entrypoint.sh

# Clean up APT when done.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /tmp/* /var/tmp/* && rm -rf /var/lib/{apt,dpkg,cache,log}/
