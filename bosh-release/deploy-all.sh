#!/bin/bash

set -e

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
MYSQL_DRIVER=mysql-connector-java-5.1.34-bin.jar

if [ ! -f ../../$APIM_PACK ]; then
    echo -e "---> APIM 2.1.0 pack not found!"
    exit 1
fi

if [ ! -f ../../$ANALYTICS_PACK ]; then
    echo -e "---> APIM Analytics 2.1.0 pack not found!"
    exit 1
fi

if [ ! -f ../../$JDK ]; then
    echo -e "---> JDK distribution (jdk-8u144-linux-x64.tar.gz) not found!"
    exit 1
fi

if [ ! -f ../../$MYSQL_DRIVER ]; then
    echo -e "---> MySQL Driver (mysql-connector-java-5.1.34-bin.jar) not found!"
    exit 1
fi

if [ ! -x "$(command -v git)" ]; then
    echo -e "---> Please install Git client."
    exit 1
fi

if [ ! -x "$(command -v docker)" ]; then
    echo -e "---> Please install Docker."
    exit 1
fi

if [ "$1" == "--force" ]; then
    echo -e "---> Killing MySQL docker container..."
    docker rm $(docker stop mysql-5.7) && docker ps -a
fi

#going to parent directory
cd ../../

APIM_PACK=$(ls wso2am-2.1.0.*.zip)
ANALYTICS_PACK=$(ls wso2am-analytics-2.1.0.*.zip)

cp $APIM_PACK $APIM_NAME.zip
cp $ANALYTICS_PACK $ANALYTICS_NAME.zip

mysql_analytics_host=localhost
mysql_apim_host=localhost
current_path=`pwd`

if [ ! "$(docker ps -q -f name=mysql-5.7)" ]; then
    echo -e "---> Starting MySQL docker container..."
    container_id=$(docker run -d --name mysql-5.7 -p 3306:3306 -e MYSQL_ROOT_HOST=% -e MYSQL_ROOT_PASSWORD=$mysql_apim_password -v ${current_path}/wso2am-2.1.0/dbscripts/:/dbscripts/ mysql:5.7.19)
    echo $container_id

    docker ps -a
    echo -e "---> Waiting for MySQL to start on 3306..."
    while ! nc -z $mysql_apim_host 3306; do
        sleep 1
        printf "."
    done
    echo ""
    echo -e "---> MySQL Started."
else
    echo -e "---> MySQL is already running..."
fi

if [ ! -d wso2am-2.1.0 ]; then
    echo -e "---> Extracting APIM 2.1.0 database scripts..."
    unzip -q $APIM_PACK
fi

echo -e "---> Creating databases..."
docker exec -it mysql-5.7 mysql -h $mysql_apim_host -u $mysql_apim_username -p$mysql_apim_password -e "DROP DATABASE IF EXISTS "$am_db"; DROP DATABASE IF EXISTS "$um_db"; DROP DATABASE IF EXISTS "$reg_db"; CREATE DATABASE "$am_db"; CREATE DATABASE "$um_db"; CREATE DATABASE "$reg_db";"
docker exec -it mysql-5.7 mysql -h $mysql_analytics_host -u $mysql_analytics_username -p$mysql_analytics_password -e "DROP DATABASE IF EXISTS "$event_store_db"; DROP DATABASE IF EXISTS "$processed_data_db"; DROP DATABASE IF EXISTS "$stats_db"; CREATE DATABASE "$event_store_db"; CREATE DATABASE "$processed_data_db"; CREATE DATABASE "$stats_db";"

echo -e "---> Creating tables..."
docker exec -it mysql-5.7 mysql -h $mysql_apim_host -u $mysql_apim_username -p$mysql_apim_password -e "USE "$am_db"; SOURCE /dbscripts/apimgt/mysql5.7.sql; USE "$um_db"; SOURCE /dbscripts/mysql5.7.sql; USE "$reg_db"; SOURCE /dbscripts/mysql5.7.sql;"

if [ ! -d bosh-deployment ]; then
    echo -e "---> Cloning https://github.com/cloudfoundry/bosh-deployment..."
    git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment
fi

if [ ! -d vbox ]; then
    echo -e "---> Creating envionment dir..."
    mkdir vbox
fi

if [ "$1" == "--force" ]; then
    echo -e "---> Deleting existing environment..."
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

echo -e "---> Creating environment..."
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

echo -e "---> Setting alias for the environment..."
bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)

echo -e "---> Loging in..."
bosh -e vbox login --client=admin --client-secret=$(bosh int vbox/creds.yml --path /admin_password)

cd pivotal-cf-apim/bosh-release/ 
echo -e "---> Adding blobs..."
bosh -e vbox add-blob ../../jdk-8u144-linux-x64.tar.gz oraclejdk/jdk-8u144-linux-x64.tar.gz
bosh -e vbox add-blob ../../$MYSQL_DRIVER mysqldriver/$MYSQL_DRIVER
bosh -e vbox add-blob ../../wso2am-2.1.0.zip wso2apim/wso2am-2.1.0.zip
bosh -e vbox add-blob ../../wso2am-analytics-2.1.0.zip wso2apim_analytics/wso2am-analytics-2.1.0.zip

echo -e "---> Uploading blobs..."
bosh -e vbox -n upload-blobs

echo -e "---> Creating bosh release..."
bosh -e vbox create-release --force

echo -e "---> Uploading bosh release..."
bosh -e vbox upload-release

if [ ! -f bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz ]; then
    echo -e "---> Stemcell does not exist! Downloading..."
    wget https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz
fi

echo -e "---> Uploading Stemcell..."
bosh -e vbox upload-stemcell bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz

echo -e "---> Deploying bosh release..."
yes | bosh -e vbox -d wso2apim deploy wso2apim-manifest.yml

os_name=`uname`
echo -e "---> Adding route to bosh lite VM..."
if [[ "$os_name" == 'Darwin' ]]; then
    sudo route add -net 10.244.0.0/16 192.168.50.6 
else
    sudo route add -net 10.244.0.0/16 gw 192.168.50.6
fi

echo -e "---> Listing VMs..."
bosh -e vbox vms
