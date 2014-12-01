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


if [ -z ${PIWIK_RELATIVE_URL_ROOT+x} ]
then
  PIWIK_RELATIVE_URL_ROOT="/piwik/" 
fi

echo ">> making piwik available beneath: $PIWIK_RELATIVE_URL_ROOT"
mkdir -p "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"
cp -a /piwik/* "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"

chown -R www-data:www-data "/usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT"
chmod -R 0755 /usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT\tmp

if [ -z ${PIWIK_MYSQL_PASSWORD+x} ] || [ -z ${PIWIK_MYSQL_USER+x} ]
  echo ">> piwik started, initial setup needs to be done in browser!"
  echo ">> be fast! - anyone with access to your server can configure it!"
  exit 0
fi

echo 
echo ">> #####################"
echo ">> init piwik"
echo ">> #####################"
echo

nginx &
sleep 4

if [ `echo "SHOW TABLES FROM $PIWIK_MYSQL_DBNAME;" | mysql -h $PIWIK_MYSQL_HOST -P $PIWIK_MYSQL_PORT -u $PIWIK_MYSQL_USER -p$PIWIK_MYSQL_PASSWORD | grep "$PIWIK_MYSQL_PREFIX" | wc -l` -lt 1 ]
then
  echo ">> no DB installed, MYSQL User or Password specified - seems like the first start"
  rm /usr/share/nginx/html$PIWIK_RELATIVE_URL_ROOT\config/config.ini.php

  echo ">> init DB"
  wget -O - http://localhost$PIWIK_RELATIVE_URL_ROOT\index.php?action=databaseSetup \
  --post-data="host=$PIWIK_MYSQL_HOST:$PIWIK_MYSQL_PORT&username=$PIWIK_MYSQL_USER&password=$PIWIK_MYSQL_PASSWORD&dbname=$PIWIK_MYSQL_DBNAME&tables_prefix=$PIWIK_MYSQL_PREFIX&adapter=PDO%5CMYSQL&submit=n%C3%A4chste+%C2%BB" \
  &> /dev/null

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
  wget -O - http://localhost$PIWIK_RELATIVE_URL_ROOT\index.php?action=setupSuperUser&module=Installation \
  --post-data="login=$PIWIK_ADMIN&password=$PIWIK_ADMIN_PASSWORD&password_bis=$PIWIK_ADMIN_PASSWORD&email=$PIWIK_ADMIN_MAIL&subscribe_newsletter_piwikorg=$PIWIK_SUBSCRIBE_NEWSLETTER&subscribe_newsletter_piwikpro=$PIWIK_SUBSCRIBE_PRO_NEWSLETTER&submit=n%C3%A4chste+%C2%BB" \
  &> /dev/null

  echo ">> add first website"
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
  wget -O - http://localhost$PIWIK_RELATIVE_URL_ROOT\index.php?action=firstWebsiteSetup&module=Installation \
  --post-data="siteName=$SITE_NAME&url=$SITE_URL&timezone=$SITE_TIMEZONE&ecommerce=$SITE_ECOMMERCE&submit=n%C3%A4chste+%C2%BB" \
  &> /dev/null

  echo ">> set client ip settings"
  if [ -z ${ANONYMISE_IP+x} ]
  then
    ANONYMISE_IP=1
  fi
  
  if [ -z ${DO_NOT_TRACK+x} ]
  then
    DO_NOT_TRACK=1
  fi
  wget -O - http://localhost$PIWIK_RELATIVE_URL_ROOT\index.php?action=finished&module=Installation \
  --post-data="do_not_track=$DO_NOT_TRACK&anonymise_ip=$ANONYMISE_IP&submit=Weiter+zu+Piwik+%C2%BB" \
  &> /dev/null
fi

echo ">> update CorePlugins"
wget -O - http://localhost$PIWIK_RELATIVE_URL_ROOT\index.php?updateCorePlugins=1 &> /dev/null

killall nginx

cat EOF<<
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
