#/bin/bash

if [ ! -z ${PIWIK_NOT_BEHIND_PROXY+x} ]
then
  echo ">> disable reverse proxy settings - connect to piwik directly"
  sed -i '4,5d' /piwik/config/config.ini.php
else
  echo ">> piwik is configured to listen behind a reverse proxy now"
fi

if [ ! -z ${PIWIK_HSTS_HEADERS_ENABLE+x} ]
then
  echo ">> HSTS Headers enabled"
  sed -i 's/#add_header Strict-Transport-Security/add_header Strict-Transport-Security/g' /etc/nginx/conf.d/nginx-piwik.conf

  if [ ! -z ${PIWIK_HSTS_HEADERS_ENABLE_NO_SUBDOMAINS+x} ]
  then
    echo ">> HSTS Headers configured without includeSubdomains"
    sed -i 's/; includeSubdomains//g' /etc/nginx/conf.d/nginx-piwik.conf
  fi
else
  echo ">> HSTS Headers disabled"
fi

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


if [ -z ${PIWIK_RELATIVE_URL_ROOT+x} ]
then
  PIWIK_RELATIVE_URL_ROOT="/piwik/" 
fi

echo ">> making piwik available beneath: $PIWIK_RELATIVE_URL_ROOT"
# adding softlink for nginx connection
echo ">> adding softlink from /piwik to $PIWIK_RELATIVE_URL_ROOT"
mkdir -p "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"

PIWIK_RELATIVE_URL_ROOT_WITHOUT_SLASH=$(echo "$PIWIK_RELATIVE_URL_ROOT" | sed 's/\/$//')

echo ">> checking softlink /usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT_WITHOUT_SLASH" 
if [ ! -h "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT_WITHOUT_SLASH" ]
then
  echo ">> creating softlink"
  rm -rf "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT_WITHOUT_SLASH"
  ln -s /piwik "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT_WITHOUT_SLASH"
else
  echo ">> doesn't create softlink - it already exists"
fi

chown -R www-data:www-data "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"
chmod -R 0755 /usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT\tmp

if [ -z ${PIWIK_MYSQL_PASSWORD+x} ] || [ -z ${PIWIK_MYSQL_USER+x} ]
then
  echo ">> piwik started, initial setup needs to be done in browser!"
  echo ">> be fast! - anyone with access to your server can configure it!"
  exit 0
fi

echo 
echo ">> #####################"
echo ">> init piwik"
echo ">> #####################"
echo

nginx 2> /dev/null > /dev/null &

sleep 4

if [ `echo "SHOW TABLES FROM $PIWIK_MYSQL_DBNAME;" | mysql -h $PIWIK_MYSQL_HOST -P $PIWIK_MYSQL_PORT -u $PIWIK_MYSQL_USER -p$PIWIK_MYSQL_PASSWORD | grep "$PIWIK_MYSQL_PREFIX" | wc -l` -lt 1 ]
then
  echo ">> no DB installed, MYSQL User or Password specified - seems like the first start"
  rm /usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT\config/config.ini.php

  echo ">> init Piwik"
  if [ -z ${PIWIK_ADMIN+x} ]
  then
    PIWIK_ADMIN="admin"
    echo ">> piwik admin user: $PIWIK_ADMIN"
  fi
  
  if [ -z ${PIWIK_ADMIN_PASSWORD+x} ]
  then
    PIWIK_ADMIN_PASSWORD=`perl -e 'my @chars = ("A".."Z", "a".."z"); my $string; $string .= $chars[rand @chars] for 1..10; print $string;'`
    echo ">> generated piwik admin password: $PIWIK_ADMIN_PASSWORD"
  fi
  
  if [ -z ${PIWIK_SUBSCRIBE_NEWSLETTER+x} ]
  then
    PIWIK_SUBSCRIBE_NEWSLETTER=0
  fi
  
  if [ -z ${PIWIK_SUBSCRIBE_PRO_NEWSLETTER+x} ]
  then
    PIWIK_SUBSCRIBE_PRO_NEWSLETTER=0
  fi
  
  if [ -z ${PIWIK_ADMIN_MAIL+x} ]
  then
    PIWIK_ADMIN_MAIL="no@no.tld"
    PIWIK_SUBSCRIBE_NEWSLETTER=0
    PIWIK_SUBSCRIBE_PRO_NEWSLETTER=0
  fi

  if [ -z ${SITE_NAME+x} ]
  then
    SITE_NAME="My local Website"
  fi
  
  if [ -z ${SITE_URL+x} ]
  then
    SITE_URL="http://localhost"
  fi
  
  if [ -z ${SITE_TIMEZONE+x} ]
  then
    SITE_TIMEZONE="Europe/Berlin"
  fi
  
  if [ -z ${SITE_ECOMMERCE+x} ]
  then
    SITE_ECOMMERCE=0
  fi

  if [ -z ${ANONYMISE_IP+x} ]
  then
    ANONYMISE_IP=1
  fi
  
  if [ -z ${DO_NOT_TRACK+x} ]
  then
    DO_NOT_TRACK=1
  fi


  echo ">> piwik wizard: #1 open installer"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #2 open system check"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=systemCheck&trackerStatus=0" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #3 open database settings"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=databaseSetup&trackerStatus=0&clientProtocol=https" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=systemCheck&trackerStatus=0' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #4 store database settings"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=databaseSetup&trackerStatus=0&clientProtocol=https" \
  -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Origin: https://localhost' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://localhost/piwik/index.php?action=databaseSetup&trackerStatus=0&clientProtocol=https' -H 'Connection: keep-alive' --compressed \
  --data-urlencode host="$PIWIK_MYSQL_HOST:$PIWIK_MYSQL_PORT" \
  --data-urlencode username="$PIWIK_MYSQL_USER" \
  --data-urlencode password="$PIWIK_MYSQL_PASSWORD" \
  --data-urlencode dbname="$PIWIK_MYSQL_DBNAME" \
  --data-urlencode tables_prefix="$PIWIK_MYSQL_PREFIX" \
  --data 'adapter=PDO%5CMYSQL&submit=Next+%C2%BB' \
  2> /dev/null | grep " % Done"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=tablesCreation&trackerStatus=0&clientProtocol=https&module=Installation" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=databaseSetup&trackerStatus=0&clientProtocol=https' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #5 open piwik settings"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=setupSuperUser&trackerStatus=0&clientProtocol=https&module=Installation" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=tablesCreation&trackerStatus=0&clientProtocol=https&module=Installation' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #6 store piwik settings"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=setupSuperUser&trackerStatus=0&clientProtocol=https&module=Installation" \
  -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Origin: https://localhost' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://localhost/piwik/index.php?action=setupSuperUser&trackerStatus=0&clientProtocol=https&module=Installation' -H 'Connection: keep-alive' --compressed \
  --data-urlencode login="$PIWIK_ADMIN" \
  --data-urlencode password="$PIWIK_ADMIN_PASSWORD" \
  --data-urlencode password_bis="$PIWIK_ADMIN_PASSWORD" \
  --data-urlencode email="$PIWIK_ADMIN_MAIL" \
  --data-urlencode subscribe_newsletter_piwikorg="$PIWIK_SUBSCRIBE_NEWSLETTER" \
  --data-urlencode subscribe_newsletter_piwikpro="$PIWIK_SUBSCRIBE_PRO_NEWSLETTER" \
  --data 'submit=Next+%C2%BB' \
  2> /dev/null | grep " % Done"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=firstWebsiteSetup&trackerStatus=0&clientProtocol=https&module=Installation" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=setupSuperUser&trackerStatus=0&clientProtocol=https&module=Installation' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #7 store piwik site settings"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=firstWebsiteSetup&trackerStatus=0&clientProtocol=https&module=Installation" \
  -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Origin: https://localhost' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://localhost/piwik/index.php?action=firstWebsiteSetup&trackerStatus=0&clientProtocol=https&module=Installation' -H 'Connection: keep-alive' --compressed \
  --data-urlencode siteName="$SITE_NAME" \
  --data-urlencode url="$SITE_URL" \
  --data-urlencode timezone="$SITE_TIMEZONE" \
  --data-urlencode ecommerce="$SITE_ECOMMERCE" \
  --data 'submit=Next+%C2%BB' \
  2> /dev/null | grep " % Done"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=trackingCode&trackerStatus=0&clientProtocol=https&module=Installation&site_idSite=1&site_name=default" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=firstWebsiteSetup&trackerStatus=0&clientProtocol=https&module=Installation' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
  echo ">> piwik wizard: #8 skip js page"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=finished&trackerStatus=0&clientProtocol=https&module=Installation&site_idSite=1&site_name=default" -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=trackingCode&trackerStatus=0&clientProtocol=https&module=Installation&site_idSite=1&site_name=justabot' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5

  echo ">> piwik wizard: #9 final settings"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php?action=finished&trackerStatus=0&clientProtocol=https&module=Installation&site_idSite=1&site_name=default" \
  -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Origin: https://localhost' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://localhost/piwik/index.php?action=finished&trackerStatus=0&clientProtocol=https&module=Installation&site_idSite=1&site_name=justabot' -H 'Connection: keep-alive' --compressed \
  --data-urlencode do_not_track="$DO_NOT_TRACK" \
  --data-urlencode anonymise_ip="$ANONYMISE_IP" \
  --data 'submit=Continue+to+Piwik+%C2%BB' \
  2> /dev/null | grep " % Done"

  curl --insecure https://localhost$PIWIK_RELATIVE_URL_ROOT"index.php" \
  -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://localhost/piwik/index.php?action=finished&trackerStatus=0&clientProtocol=https&module=Installation&site_idSite=1&site_name=justabot' -H 'Cookie: pma_lang=en; pma_collation_connection=utf8_general_ci; pma_mcrypt_iv=n%2Bxpbn2a%2Btg%3D; pmaUser-1=L60fYDVIaz0%3D' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed \
  2> /dev/null | grep " % Done"

  sleep 5
  
fi

echo ">> update CorePlugins"
curl http://localhost$PIWIK_RELATIVE_URL_ROOT\index.php?updateCorePlugins=1 \
2> /dev/null | grep " % Done"

sleep 2
  
killall nginx

cat <<EOF
Add the following JS-Code to your Site -> don't forget to change the URLs ;)

<!-- Piwik -->
<script type="text/javascript">
  var _paq = _paq || [];
  _paq.push(['trackPageView']);
  _paq.push(['enableLinkTracking']);
  (function() {
    var u="//!!!YOUR-URL!!!/";
    _paq.push(['setTrackerUrl', u+'piwik.php']);
    _paq.push(['setSiteId', 1]);
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
    g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
  })();
</script>
<noscript><p><img src="//!!!YOUR-URL!!!/piwik.php?idsite=1" style="border:0;" alt="" /></p></noscript>
<!-- End Piwik Code -->
EOF

if [ ! -z ${PIWIK_PLUGINS_ACTIVATE+x} ]
then
  for plugin in ${PIWIK_PLUGINS_ACTIVATE}
  do
    /piwik/console plugin:activate $plugin
  done
fi

