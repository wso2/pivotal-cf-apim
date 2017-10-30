#!/bin/bash

#APIM MySQL
mysql_apim_host="172.17.0.1"
mysql_apim_username="root"
mysql_apim_password="root"
am_db="am_db"
um_db="um_db"
reg_db="reg_db"

#Analytics MySQL
mysql_analytics_host="172.17.0.1"
mysql_analytics_username="root"
mysql_analytics_password="root"
event_store_db="event_store_db"
processed_data_db="processed_data_db"
stats_db="stats_db"

APIM_PACK=$(ls wso2am-2.1.0.*.zip)
ANALYTICS_PACK=$(ls wso2am-analytics-2.1.0.*.zip)
JDK=$(ls jdk-8u144-linux-x64.tar.gz)
MYSQL_DRIVER=$(ls mysql-connector-java-5.1.24-bin.jar)

if [ ! -x "$(command -v docker)" ]; then
    echo -e "\e[32m>>  Please install Docker. \e[0m"
    exit 1
fi

if [ ! -x "$(command -v bosh)" ]; then
    echo -e "\e[32m>>  Please install Bosh CLI v2. \e[0m"
    exit 1
fi

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

