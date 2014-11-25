# Docker Piwik Container (marvambass/piwik)
_maintained by MarvAmBass_

## What is it

This Dockerfile (available as ___marvambass/piwik___) gives you a completly secure piwik.

It's based on the [marvambass/nginx-ssl-php](https://registry.hub.docker.com/u/marvambass/nginx-ssl-php/) Image

View in Docker Registry [marvambass/piwik](https://registry.hub.docker.com/u/marvambass/piwik/)

View in GitHub [MarvAmBass/docker-piwik](https://github.com/MarvAmBass/docker-piwik)

## Environment variables and defaults

* __DH\_SIZE__
 * default: 512 fast but a bit insecure. if you need more security just use a higher value
* __PIWIK\_MYSQL\_HOST__
 * default: _mysql_
* __PIWIK\_MYSQL\_PORT__
 * default: _3306_ - if you use a different mysql port change it
* __PIWIK\_MYSQL\_USER__
 * no default - if null it will start piwik in initial mode
* __PIWIK\_MYSQL\_PASSWORD__
 * no default - if null it will start piwik in initial mode
* __PIWIK\_MYSQL\_DBNAME__
 * default: _piwik_
* __PIWIK\_MYSQL\_PREFIX__
 * default: _piwik\__
* __PIWIK\_RELATIVE\_URL\_ROOT__
 * default: _/_ - you can chance that to /stats or what you need

## Using the marvambass/piwik Container

First you need a running MySQL Container (you could use: [marvambass/mysql](https://registry.hub.docker.com/u/marvambass/mysql/)).

You need to _--link_ your mysql container to marvambass/piwik with the name __mysql__

    docker run -d -p 80:80 -p 443:443 --link mysql:mysql --name piwik marvambass/piwik
