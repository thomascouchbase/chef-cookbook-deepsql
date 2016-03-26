#!/bin/bash

#
# The purpose of this script is to create rpm or deb tar bundles.
#
# The benefit of this serves those customers with secured environments
# where all deb files must be served from in house package repositories
# and where those bundles have been scanned by the likes of VeraCode.
# This applies to several firms in the finance, telco, insurance, and
# health care industries.
#
# The packages should be placed in a package repository layout such as
# the following:
#
#  redhat/
#      el6/
#          x86_64/
#              deepsql/*
#      el7/
#          x86_64/
#              deepsql/*
#  ubuntu/
#      precise/
#          x86_64/
#              deepsql/*
#      trusty/
#          x86_64/
#              deepsql/*
#
# Provided the above package repository layout is used, the following
# Chef attribute may be used to customize where the deepSQL Chef Library
# retrieves bundles:
#
#   repository_baseurl
#
# By default the repository_baseurl is:
#
#   https://deepsql.s3.amazonaws.com/repository
#

: ${DEEP_ACTCODE:="000000000000000000000000000000000"}

JSON_URL="https://deepis.com/dlt.php?action=dl&contactid=$DEEP_ACTCODE&filename=https://s3.amazonaws.com/deepdownloads/deepprod-latest.json"

wget -qO- $JSON_URL | grep latest_release | grep deepsql | grep -v "OS_LIST='tools'" | awk -F\" '{print $4}' | sed "s/@ACTID@/$DEEP_ACTCODE/g" | head -n 1 > ./urls.sh

source ./urls.sh

for MYSQL_VERSION in $MYSQL_VERSIONS ; do
    if [[ $MYSQL_VERSION =~ "deepsql-5.6" ]] ; then
        if [[ $MYSQL_VERSION =~ "-bundle" ]] ; then
            DEEP_BUNDLE_VERSION=$MYSQL_VERSION

        else
            DEEP_PLUGIN_VERSION=$MYSQL_VERSION
        fi
    else
        echo ""
        echo "Unsupported DeepSQL version $MYSQL_VERSION"
        echo ""

        exit_installer

    fi
done

for OS_DIST in $OS_LIST; do

    if [[ "${OS_DIST}" == DOCKER ]]
    then
        continue
    fi

    echo "Packaging ${OS_DIST}..."

    rm -fr /tmp/$OS_DIST
    mkdir /tmp/$OS_DIST
    (
        cd /tmp/$OS_DIST

        DEEP_BUNDLE_URL=${DEEP_URLS["${OS_DIST}_${DEEP_BUNDLE_VERSION}_${VERSION}"]}
        wget --quiet --no-check-certificate $DEEP_BUNDLE_URL -O bundle.tar
        ls /tmp/$OS_DIST
        tar xf bundle.tar
        rm bundle.tar
        purge_list=('deepsql-*.src' 'deepsql-source' 'deepsql-devel' 'deepsql-embedded-devel' 'deepsql-testsuite' 'deepsql-test' 'deepsql-bench' 'libdeepsqlclient-dev' 'libdeepsqld-dev')
        for item in "${purge_list[@]}"; do
            `rm -f /tmp/$OS_DIST/${item}*`
        done

        DEEP_PLUGIN_URL=${DEEP_URLS["${OS_DIST}_${DEEP_PLUGIN_VERSION}_${VERSION}"]}

        if [[ "${OS_DIST}" == RHEL* ]]
        then
            wget --quiet --no-check-certificate $DEEP_PLUGIN_URL -O deepsql-plugin_5.6.28_amd64.rpm
            tar cf deepsql_5.6.28_x86_64.rpm-bundle.tar *.rpm
            rm *.rpm
        else
            wget --quiet --no-check-certificate $DEEP_PLUGIN_URL -O deepsql-plugin_5.6.28_amd64.deb
            tar cf deepsql_5.6.28_amd64.deb-bundle.tar *.deb
            rm *.deb
        fi
    )

done
