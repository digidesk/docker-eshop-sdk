#!/bin/bash

# Flags possible:
# -e for shop edition. Possible values: ce/pe/ee

edition='ee'
while getopts e: flag; do
  case "${flag}" in
  e) edition=${OPTARG} ;;
  *) ;;
  esac
done

SCRIPT_PATH=$(dirname ${BASH_SOURCE[0]})
cd $SCRIPT_PATH/../../ || exit

# Prepare services configuration
make setup
make addbasicservices
make file=services/adminer.yml addservice
#make file=services/selenium-chrome.yml addservice
#make file=services/node.yml addservice

# Configure containers
perl -pi\
  -e 's#error_reporting = .*#error_reporting = E_ALL ^ E_WARNING ^ E_DEPRECATED#g;'\
  containers/php/custom.ini

perl -pi\
  -e 's#/var/www/#/var/www/source/#g;'\
  containers/httpd/project.conf

# Setup PHP with Shop files
mkdir source && \
docker compose up --build -d php && \
docker compose exec -T php /bin/bash -c "~/composer_auth.sh" && \
docker compose exec -T php composer create-project --no-dev oxid-esales/oxideshop-project . dev-b-7.1-${edition} && \
make down && \

# Start all containers
make up && \

perl -pi\
  -e 'print "SetEnvIf Authorization \"(.*)\" HTTP_AUTHORIZATION=\$1\n\n" if $. == 1'\
  source/source/.htaccess && \

docker compose exec -T php composer require oxid-esales/developer-tools:dev-b-7.0.x --no-update && \
docker compose exec -T php composer update && \

# Setup the database
"${SCRIPT_PATH}/../oxid-esales/parts/shared/setup_database.sh" && \

docker compose exec -T php vendor/bin/oe-console oe:theme:activate apex && \
"${SCRIPT_PATH}/../oxid-esales/parts/shared/create_admin.sh" && \

echo "Done!"
