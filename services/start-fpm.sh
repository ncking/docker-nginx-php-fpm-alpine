#!/usr/bin/with-contenv sh
set -e;

# Start PHP-FPM
/usr/sbin/php-fpm7 -R --nodaemonize
