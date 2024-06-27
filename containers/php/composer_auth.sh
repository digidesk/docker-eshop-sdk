#!/usr/bin/env bash
set -e

COMPOSER_HOME="$HOME/.composer"

# from environment
OXSATISUSR=${OXID_SATIS_USER}
OXSATISPWD=${OXID_SATIS_PWD}

# composer auth
if [ ! -f ${COMPOSER_HOME}/auth.json ]
then

    if [ ! -d ${COMPOSER_HOME} ]
    then
        mkdir ${COMPOSER_HOME}
    fi

    if [ "$OXSATISUSR" == "PE" ]
    then
      echo "{ \"http-basic\": { \"professional-edition.packages.oxid-esales.com\": { \"username\": \"PE\", \"password\": \"${OXSATISPWD}\" } } }" > ${COMPOSER_HOME}/auth.json
    elif [ "$OXSATISUSR" == "EE" ]; then
      echo "{ \"http-basic\": { \"enterprise-edition.packages.oxid-esales.com\": { \"username\": \"EE\", \"password\": \"${OXSATISPWD}\" } } }" > ${COMPOSER_HOME}/auth.json
    fi

    echo "Composer AUTH configured"
fi
