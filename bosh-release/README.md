# WSO2 API Manager BOSH Release

A BOSH release for deploying WSO2 API Manager 2.1.0 with Analytics on BOSH Director.

## Quick Start Guide

1. Install [bosh v2][1], ruby, VirtualBox, git client, mysql client (5.7) and docker.
2. Create a directory (say `apim`) and copy following binaries in to it. Make sure to have exact versions as they are used in the scripts.

		jdk-8u144-linux-x64.tar.gz  
		mysql-connector-java-5.1.24-bin.jar  
		Wso2am-2.1.0.zip WUM Updated pack 
		Wso2am-analytics-2.1.0.zip WUM Updated pack


3. Go inside the new directory and clone [pivotal-cf-apim][2] repo.

        $ clone https://github.com/bhathiya/pivotal-cf-apim
       
    Then the folder structure should look like this.
    
        ├─ apim
           ├── pivotal-cf-apim
           ├── jdk-8u144-linux-x64.tar.gz
           ├── mysql-connector-java-5.1.24-bin.jar
           ├── wso2am-2.1.0.1508395562471.zip
           └── wso2am-analytics-2.1.0.1508329260349.zip
           
4. Go inside **pivotal-cf-apim/bosh-release/** directory.          

	    $ cd pivotal-cf-apim/bosh-release/
        
5. Run deploy-all.sh script. You will be asked for the superuser password in the middle.

        $ ./deploy-all.sh
        
    If everything goes successful, you will see something like this at the end.
    
		Deployment 'wso2apim'

        Instance                                                 Process State  AZ  IPs          VM CID                                VM Type  
        wso2apim/06ade672-ecc8-425b-99a4-e72cf0210c59            running        -   10.244.15.2  4e25c655-f23d-47f7-6a68-98b0d3bd9843  wso2apim-resource-pool  
        wso2apim_analytics/85eb9ace-7bd4-4075-9dd4-b1b5527bf533  running        -   10.244.15.3  7a8a9524-3649-491e-7427-d74f0949794b  wso2apim_analytics-resource-pool  

        2 vms
    
    Now you can access APIM by following URLs.
        
    	https://10.244.15.2:9443/publisher
        https://10.244.15.2:9443/store
        https://10.244.15.2:9443/carbon
        https://10.244.15.2:9443/admin
        
	
> **Note**: If you want to stop and remove everything (i.e. MySQL container and entire Bosh Environment), run undeploy.sh script>
> 
>        $ ./undeploy.sh
        

[1]: http://bosh.io
[2]: https://github.com/bhathiya/pivotal-cf-apim
[image]: https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png

<br />    

## What happens inside deploy-all.sh:         
   
1. Check if required binaries are available.

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

2. Check if required tools are installed.

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

3. Go to parent directory and rename binaries.

        #going to parent directory
        cd ../../

        APIM_PACK=$(ls wso2am-2.1.0.*.zip)
        ANALYTICS_PACK=$(ls wso2am-analytics-2.1.0.*.zip)

        cp $APIM_PACK $APIM_NAME.zip
        cp $ANALYTICS_PACK $ANALYTICS_NAME.zip

4. Pull MySQL docker image and start it.

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

5. Creat databases and tables on MySQL.

        if [ ! -d wso2am-2.1.0 ]; then
            echo -e "\e[32m>> Extracting APIM 2.1.0 database scripts... \e[0m"
            unzip -q $APIM_PACK
        fi

        echo -e "\e[32m>> Creating databases... \e[0m"
        mysql -h $mysql_apim_host -u $mysql_apim_username -p$mysql_apim_password -e "DROP DATABASE IF EXISTS "$am_db"; DROP DATABASE IF EXISTS "$um_db"; DROP DATABASE IF EXISTS "$reg_db"; CREATE DATABASE "$am_db"; CREATE DATABASE "$um_db"; CREATE DATABASE "$reg_db";"
        mysql -h $mysql_analytics_host -u $mysql_analytics_username -p$mysql_analytics_password -e "DROP DATABASE IF EXISTS "$event_store_db"; DROP DATABASE IF EXISTS "$processed_data_db"; DROP DATABASE IF EXISTS "$stats_db"; CREATE DATABASE "$event_store_db"; CREATE DATABASE "$processed_data_db"; CREATE DATABASE "$stats_db";"

        echo -e "\e[32m>> Creating tables... \e[0m"
        mysql -h $mysql_apim_host -u $mysql_apim_username -p$mysql_apim_password -e "USE "$am_db"; SOURCE wso2am-2.1.0/dbscripts/apimgt/mysql5.7.sql; USE "$um_db"; SOURCE wso2am-2.1.0/dbscripts/mysql5.7.sql; USE "$reg_db"; SOURCE wso2am-2.1.0/dbscripts/mysql5.7.sql;"


6. Clone [bosh-deployment][3] git repo.

        if [ ! -d bosh-deployment ]; then
            echo -e "\e[32m>> Cloning https://github.com/cloudfoundry/bosh-deployment... \e[0m"
            git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment
        fi

7. Create bosh environment.

        if [ ! -d vbox ]; then
            echo -e "\e[32m>> Creating envionment dir... \e[0m"
            mkdir vbox
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

8. Once VM with BOSH Director is running, point Bosh CLI to it, saving the environment with the alias `vbox`.

        echo -e "\e[32m>> Setting alias for the environment... \e[0m"
        bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)

9. Login to Bosh Director using generated password

        echo -e "\e[32m>> Loging in... \e[0m"
        bosh -e vbox login --client=admin --client-secret=$(bosh int vbox/creds.yml --path /admin_password

10. Upload binaries as blobs.

        cd pivotal-cf-apim/bosh-release/ 
        echo -e "\e[32m>> Adding blobs... \e[0m"
        bosh -e vbox add-blob ../../jdk-8u144-linux-x64.tar.gz oraclejdk/jdk-8u144-linux-x64.tar.gz
        bosh -e vbox add-blob ../../mysql-connector-java-5.1.24-bin.jar mysqldriver/mysql-connector-java-5.1.24-bin.jar
        bosh -e vbox add-blob ../../wso2am-2.1.0.zip wso2apim/wso2am-2.1.0.zip
        bosh -e vbox add-blob ../../wso2am-analytics-2.1.0.zip wso2apim_analytics/wso2am-analytics-2.1.0.zip

        echo -e "\e[32m>> Uploading blobs... \e[0m"
        bosh -e vbox -n upload-blobs

11. Create APIM Bosh release and upload it to BOSH Director.

        echo -e "\e[32m>> Creating bosh release... \e[0m"
        bosh -e vbox create-release --force

        echo -e "\e[32m>> Uploading bosh release... \e[0m"
        bosh -e vbox upload-release

12. Download latest bosh-lite warden stemcell from bosh.io and upload it to BOSH Director.

        if [ ! -f bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz ]; then
            echo -e "\e[32m>> Stemcell does not exist! Downloading... \e[0m"
            wget https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz
        fi

        echo -e "\e[32m>> Uploading Stemcell... \e[0m"
        bosh -e vbox upload-stemcell bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz

13. Deploy the WSO2 API Manager bosh release manifest in BOSH Director.

        echo -e "\e[32m>> Deploying bosh release... \e[0m"
        yes | bosh -e vbox -d wso2apim deploy wso2apim-manifest.yml

14. Add route to VirtualBox network.

        echo -e "\e[32m>> Adding route... \e[0m"
        sudo route add -net 10.244.0.0/16 gw 192.168.50.6

15. List VMs.

        echo -e "\e[32m>> Listing VMs... \e[0m"
        bosh -e vbox vms


[1]: http://bosh.io
[2]: https://github.com/bhathiya/pivotal-cf-apim
[3]: https://github.com/cloudfoundry/bosh-deployment 


## References

* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)

