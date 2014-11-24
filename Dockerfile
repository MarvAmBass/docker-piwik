FROM marvambass/nginx-ssl-php
MAINTAINER MarvAmBass

ENV DH_SIZE 512

RUN apt-get update && apt-get install -y \
    mysql-client \
    php5-mysql \
    php5-gd \
    php5-geoip \
    php-apc \
    wget \
    unzip

# clean http directory
RUN rm -rf /usr/share/nginx/html/*

# install nginx phpmyadmin config
ADD nginx-piwik.conf /etc/nginx/conf.d/nginx-piwik.conf

RUN wget "http://builds.piwik.org/piwik-latest.zip" -O piwik.zip
RUN unzip piwik.zip
RUN rm piwik.zip

# add piwik config
ADD config.ini.php /piwik/config/config.ini.php

# add startup.sh
ADD startup-piwik.sh /opt/startup-piwik.sh
RUN chmod a+x /opt/startup-piwik.sh

# add '/opt/startup-piwik.sh' to entrypoint.sh
RUN sed -i 's/#!\/bin\/bash/#!\/bin\/bash\n\/opt\/startup-piwik.sh/g' /opt/entrypoint.sh
