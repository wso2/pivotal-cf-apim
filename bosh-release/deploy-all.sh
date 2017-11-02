#!/bin/bash

#APIM MySQL
mysql_apim_username="root"
mysql_apim_password="root"
am_db="am_db"
um_db="um_db"
reg_db="reg_db"

#Analytics MySQL
mysql_analytics_username="root"
mysql_analytics_password="root"
event_store_db="event_store_db"
processed_data_db="processed_data_db"
stats_db="stats_db"
APIM_NAME=wso2am-2.1.0
ANALYTICS_NAME=wso2am-analytics-2.1.0
APIM_PACK=wso2am-2.1.0.*.zip
ANALYTICS_PACK=wso2am-analytics-2.1.0.*.zip
JDK=jdk-8u144-linux-x64.tar.gz
MYSQL_DRIVER=mysql-connector-java-5.1.24-bin.jar

if [ ! -f ../../$APIM_PACK ]; then
    echo -e "\e[32m>> APIM 2.1.0 pack not found! \e[0m"
    exit 1
fi

if [ ! -f ../../$ANALYTICS_PACK ]; then
    echo -e "\e[32m>> APIM Analytics 2.1.0 pack not found! \e[0m"
    exit 1
fi

if [ ! -f ../../$JDK ]; then
    echo -e "\e[32m>> JDK distribution (jdk-8u144-linux-x64.tar.gz) not found! \e[0m"
    exit 1
fi

if [ ! -f ../../$MYSQL_DRIVER ]; then
    echo -e "\e[32m>> MySQL Driver (mysql-connector-java-5.1.24-bin.jar) not found! \e[0m"
    exit 1
fi

if [ ! -x "$(command -v mysql)" ]; then
    echo -e "\e[32m>> Please install MySQL client. \e[0m"
    exit 1
fi

if [ ! -x "$(command -v git)" ]; then
    echo -e "\e[32m>> Please install Git client. \e[0m"
    exit 1
fi

if [ ! -x "$(command -v docker)" ]; then
    echo -e "\e[32m>> Please install Docker. \e[0m"
    exit 1
fi

if [ "$1" == "--force" ]; then
    echo -e "\e[32m>> Killing MySQL docker container... \e[0m"
    docker rm $(docker stop mysql-5.7) && docker ps -a
fi

#going to parent directory
cd ../../

APIM_PACK=$(ls wso2am-2.1.0.*.zip)
ANALYTICS_PACK=$(ls wso2am-analytics-2.1.0.*.zip)

cp $APIM_PACK $APIM_NAME.zip
cp $ANALYTICS_PACK $ANALYTICS_NAME.zip

echo -e "\e[32m>> Pulling MySQL docker image... \e[0m"
docker pull mysql/mysql-server:5.7

if ! nc -z $mysql_apim_host 3306; then
    echo -e "\e[32m>> Starting MySQL docker container... \e[0m"
    container_id=$(docker run -d --name mysql-5.7 -p 3306:3306 -e MYSQL_ROOT_HOST=% -e MYSQL_ROOT_PASSWORD=$mysql_apim_password mysql/mysql-server:5.7)
    docker_ip=$(docker inspect $container_id | grep -w \"IPAddress\" | head -n 1 | cut -d '"' -f 4)
    mysql_analytics_host=$docker_ip
    mysql_apim_host=$docker_ip
    docker ps -a
    echo -e "\e[32m>> Waiting for MySQL to start on 3306... \e[0m"
    while ! nc -z $mysql_apim_host 3306; do
        sleep 1
        printf "."
    done
    echo ""
    echo -e "\e[32m>> MySQL Started. \e[0m"
else
    echo -e "\e[32m>> MySQL is already running... \e[0m"
fi

if [ ! -d wso2am-2.1.0 ]; then
    echo -e "\e[32m>> Extracting APIM 2.1.0 database scripts... \e[0m"
    unzip -q $APIM_PACK
fi

echo -e "\e[32m>> Creating databases... \e[0m"
mysql -h $mysql_apim_host -u $mysql_apim_username -p$mysql_apim_password -e "DROP DATABASE IF EXISTS "$am_db"; DROP DATABASE IF EXISTS "$um_db"; DROP DATABASE IF EXISTS "$reg_db"; CREATE DATABASE "$am_db"; CREATE DATABASE "$um_db"; CREATE DATABASE "$reg_db";"
mysql -h $mysql_analytics_host -u $mysql_analytics_username -p$mysql_analytics_password -e "DROP DATABASE IF EXISTS "$event_store_db"; DROP DATABASE IF EXISTS "$processed_data_db"; DROP DATABASE IF EXISTS "$stats_db"; CREATE DATABASE "$event_store_db"; CREATE DATABASE "$processed_data_db"; CREATE DATABASE "$stats_db";"

echo -e "\e[32m>> Creating tables... \e[0m"
mysql -h $mysql_apim_host -u $mysql_apim_username -p$mysql_apim_password -e "USE "$am_db"; SOURCE wso2am-2.1.0/dbscripts/apimgt/mysql5.7.sql; USE "$um_db"; SOURCE wso2am-2.1.0/dbscripts/mysql5.7.sql; USE "$reg_db"; SOURCE wso2am-2.1.0/dbscripts/mysql5.7.sql;"

if [ ! -d bosh-deployment ]; then
    echo -e "\e[32m>> Cloning https://github.com/cloudfoundry/bosh-deployment... \e[0m"
    git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment
fi

if [ ! -d vbox ]; then
    echo -e "\e[32m>> Creating envionment dir... \e[0m"
    mkdir vbox
fi

if [ "$1" == "--force" ]; then
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
fi

echo -e "\e[32m>> Creating environment... \e[0m"
bosh create-env bosh-deployment/bosh.yml \
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

echo -e "\e[32m>> Setting alias for the environment... \e[0m"
bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)

echo -e "\e[32m>> Loging in... \e[0m"
bosh -e vbox login --client=admin --client-secret=$(bosh int vbox/creds.yml --path /admin_password)

cd pivotal-cf-apim/bosh-release/ 
echo -e "\e[32m>> Adding blobs... \e[0m"
bosh -e vbox add-blob ../../jdk-8u144-linux-x64.tar.gz oraclejdk/jdk-8u144-linux-x64.tar.gz
bosh -e vbox add-blob ../../mysql-connector-java-5.1.24-bin.jar mysqldriver/mysql-connector-java-5.1.24-bin.jar
bosh -e vbox add-blob ../../wso2am-2.1.0.zip wso2apim/wso2am-2.1.0.zip
bosh -e vbox add-blob ../../wso2am-analytics-2.1.0.zip wso2apim_analytics/wso2am-analytics-2.1.0.zip

echo -e "\e[32m>> Uploading blobs... \e[0m"
bosh -e vbox -n upload-blobs

echo -e "\e[32m>> Creating bosh release... \e[0m"
bosh -e vbox create-release --force

echo -e "\e[32m>> Uploading bosh release... \e[0m"
bosh -e vbox upload-release

if [ ! -f bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz ]; then
    echo -e "\e[32m>> Stemcell does not exist! Downloading... \e[0m"
    wget https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz
fi

echo -e "\e[32m>> Uploading Stemcell... \e[0m"
bosh -e vbox upload-stemcell bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz

echo -e "\e[32m>> Deploying bosh release... \e[0m"
yes | bosh -e vbox -d wso2apim deploy wso2apim-manifest.yml

echo -e "\e[32m>> Adding route... \e[0m"
sudo route add -net 10.244.0.0/16 gw 192.168.50.6

echo -e "\e[32m>> Listing VMs... \e[0m"
bosh -e vbox vms

