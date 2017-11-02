#!/bin/bash

if [ ! -x "$(command -v docker)" ]; then
    echo -e "\e[32m>>  Please install Docker. \e[0m"
    exit 1
fi

if [ ! -x "$(command -v bosh)" ]; then
    echo -e "\e[32m>>  Please install Bosh CLI v2. \e[0m"
    exit 1
fi

cd ../../

echo -e "\e[32m>> Killing MySQL docker container... \e[0m"
docker rm $(docker stop mysql-5.7) && docker ps -a

echo -e "\e[32m>> Deleting existing environment... \e[0m"
bosh delete-env bosh-deployment/bosh.yml \
 --state vbox/state.json \
 -o bosh-deployment/virtualbox/cpi.yml \
 -o bosh-deployment/virtualbox/outbound-network.yml \
 -o bosh-deployment/bosh-lite.yml \
 -o bosh-deployment/bosh-lite-runc.yml \
 -o bosh-deployment/jumpbox-user.yml \
 --vars-store vbox/creds.yml \
 -v director_name="Bosh Lite Director" \
 -v internal_ip=192.168.50.6 \
 -v internal_gw=192.168.50.1 \
 -v internal_cidr=192.168.50.0/24 \
 -v outbound_network_name=NatNetwork

rm -rf vbox
cd pivotal-cf-apim/bosh-release/
