# Docker Piwik Container (marvambass/piwik)
_maintained by MarvAmBass_

[FAQ - All you need to know about the marvambass Containers](https://marvin.im/docker-faq-all-you-need-to-know-about-the-marvambass-containers/)

## What is it

This Dockerfile (available as ___marvambass/piwik___) gives you a completly secure piwik.

It's based on the [marvambass/nginx-ssl-php](https://registry.hub.docker.com/u/marvambass/nginx-ssl-php/) Image

View in Docker Registry [marvambass/piwik](https://registry.hub.docker.com/u/marvambass/piwik/)

View in GitHub [MarvAmBass/docker-piwik](https://github.com/MarvAmBass/docker-piwik)

## Environment variables and defaults

### For Headless installation required

Piwik Database Settings

* __PIWIK\_MYSQL\_USER__
 * no default - if null it will start piwik in initial mode
* __PIWIK\_MYSQL\_PASSWORD__
 * no default - if null it will start piwik in initial mode
* __PIWIK\_MYSQL\_HOST__
 * default: _mysql_
* __PIWIK\_MYSQL\_PORT__
 * default: _3306_ - if you use a different mysql port change it
* __PIWIK\_MYSQL\_DBNAME__
 * default: _piwik_ - don't use the symbol __-__ in there!
* __PIWIK\_MYSQL\_PREFIX__
 * default: _piwik\__
 
Piwik Admin Settings

* __PIWIK\_ADMIN__
 * default: admin - the name of the admin user
* __PIWIK\_ADMIN\_PASSWORD__
 * default: [randomly generated 10 characters] - the password for the admin user
* __PIWIK\_ADMIN\_MAIL__
 * default: no@no.tld - only needed if you are interested in one of those newsletters
* __PIWIK\_SUBSCRIBE\_NEWSLETTER__
 * __1__ or __0__ - default: _0_
* __PIWIK\_SUBSCRIBE\_PRO\_NEWSLETTER__
 * __1__ or __0__ - default: _0_

Website to Track Settings

* __SITE\_NAME__
 * default: _My local Website_
* __SITE\_URL__
 * default: _http://localhost_
* __SITE\_TIMEZONE__
 * default: _Europe/Berlin_
* __SITE\_ECOMMERCE__
 * __1__ or __0__ - default: _0_

Piwik Track Settings

* __ANONYMISE\_IP__
 * __1__ or __0__ - this will anonymise IPs - default: _1_
* __DO\_NOT\_TRACK__
 * __1__ or __0__ - this will skip browsers with do not track enabled from tracking - default: _1_
 
### Misc Settings

* __PIWIK\_RELATIVE\_URL\_ROOT__
 * default: _/piwik/_ - you can chance that to whatever you want/need
* __PIWIK\_NOT\_BEHIND\_PROXY__
 * default: not set - if set to any value the settings to listen behind a reverse proxy server will be removed
* __PIWIK\_HSTS\_HEADERS\_ENABLE__
 * default: not set - if set to any value the HTTP Strict Transport Security will be activated on SSL Channel
* __PIWIK\_HSTS\_HEADERS\_ENABLE\_NO\_SUBDOMAINS__
 * default: not set - if set together with __PIWIK\_HSTS\_HEADERS\_ENABLE__ and set to any value the HTTP Strict Transport Security will be deactivated on subdomains

### Inherited Variables

* __DH\_SIZE__
 * default: 2048 if you need more security just use a higher value
 * inherited from [MarvAmBass/docker-nginx-ssl-secure](https://github.com/MarvAmBass/docker-nginx-ssl-secure)

## Using the marvambass/piwik Container

First you need a running MySQL Container (you could use: [marvambass/mysql](https://registry.hub.docker.com/u/marvambass/mysql/)).

You need to _--link_ your mysql container to marvambass/piwik with the name __mysql__

    docker run -d -p 80:80 -p 443:443 --link mysql:mysql --name piwik marvambass/piwik
