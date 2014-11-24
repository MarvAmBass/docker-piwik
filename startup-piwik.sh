#/bin/bash

if [ -z ${PIWIK_MYSQL_HOST+x} ]
then
  PIWIK_MYSQL_HOST=mysql
fi

if [ -z ${PIWIK_MYSQL_PORT+x} ]
then
  PIWIK_MYSQL_PORT=3306
fi

if [ -z ${PIWIK_MYSQL_DBNAME+x} ]
then
  PIWIK_MYSQL_DBNAME=piwik
fi

if [ -z ${PIWIK_MYSQL_PREFIX+x} ]
then
  PIWIK_MYSQL_PREFIX="piwik_"
fi

echo ">> set MYSQL Host: $PIWIK_MYSQL_HOST"
sed -i "s/PIWIK_MYSQL_HOST/$PIWIK_MYSQL_HOST/g" /piwik/config/config.ini.php

echo ">> set MYSQL Port: $PIWIK_MYSQL_PORT"
sed -i "s/PIWIK_MYSQL_PORT/$PIWIK_MYSQL_PORT/g" /piwik/config/config.ini.php

echo ">> set MYSQL User: <hidden>"
sed -i "s/PIWIK_MYSQL_USER/$PIWIK_MYSQL_USER/g" /piwik/config/config.ini.php

echo ">> set MYSQL Password: <hidden>"
sed -i "s/PIWIK_MYSQL_PASSWORD/$PIWIK_MYSQL_PASSWORD/g" /piwik/config/config.ini.php

echo ">> set MYSQL DB Name: $PIWIK_MYSQL_DBNAME"
sed -i "s/PIWIK_MYSQL_DBNAME/$PIWIK_MYSQL_DBNAME/g" /piwik/config/config.ini.php

echo ">> set MYSQL Prefix: $PIWIK_MYSQL_PREFIX"
sed -i "s/PIWIK_MYSQL_PREFIX/$PIWIK_MYSQL_PREFIX/g" /piwik/config/config.ini.php

if [ -z ${PIWIK_MYSQL_PASSWORD+x} ] || [ -z ${PIWIK_MYSQL_USER+x} ]
then
  echo ">> no MYSQL User or Password specified - seems like the first start"
  rm /piwik/config/config.ini.php;
fi

if [ -z ${PIWIK_RELATIVE_URL_ROOT+x} ]
then
  PIWIK_RELATIVE_URL_ROOT="/" 
fi

echo ">> making piwik available beneath: $PIWIK_RELATIVE_URL_ROOT"
mkdir -p "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"
cp -a /piwik/* "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"

chown -R www-data:www-data "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"
chmod -R 0755 "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT/tmp"
