# CloudFoundry Service Broker for WSO2 API Manager

This repository contains CloudFoundry (CF) service broker for WSO2 API Manager. The service broker API has been implemented using Ballerina and it can be run on CF as an application using Docker. The servce broker does not provision WSO2 API Manager, rather it points to an existing deployment.

Refer [Quick Start](#Quick Start) for trying this out on a local machine with [PCF Dev](https://pivotal.io/pcf-dev) and [Installation](#Installation) for installing this on an existing CF environment.

## Quick Start

The quick start provides steps for installing WSO2 API Manager service broker on PCF Dev.

- Download and install PCF Dev by following [this](https://pivotal.io/platform/pcf-tutorials/getting-started-with-pivotal-cloud-foundry-dev/install-pcf-dev)

- Start PCF Dev instance:
  
  ```
  $ cf dev start
  ```

- Download Ballerina tools distribution from [ballerinalang.org](https://ballerinalang.org/) and add it's bin folder path to the PATH variable:
  
  ````
  $ export BAL_HOME="/path/to/ballerina/ballerina-tools-<version>/"
  $ export PATH=$BAL_HOME/bin:$PATH
  ````

- Download WSO2 API Manager 2.1.0 distribution from [wso2.com](http://wso2.com/api-management/), extract it and start the server:
   
  ````
  $ unzip wso2am-2.1.0.zip
  $ cd wso2am-2.1.0/
  $ bin/wso2server.sh start
  ````

- Clone this git repository:
  
  ````
  $ git clone https://github.com/imesh/wso2-apim-cf-service-broker.git
  ````

- Execute the following script to register a client in WSO2 API Manager for invoking its admin REST API:

  ````
  $ ./register-api-client.sh
  ````

- Expose following environment variables:

  ````
  $ export WSO2_APIM_TOKEN_ENDPOINT=https://localhost:8243/token
  $ export WSO2_APIM_PUBLISHER_ENDPOINT=https://localhost:9443/api/am/publisher
  $ export WSO2_APIM_PUBLISHER_UI_URL=https://localhost:9443/publisher/
  $ export WSO2_APIM_CLIENT_ID=<client-id-generated-above>
  $ export WSO2_APIM_CLIENT_SECRET=<client-secret-generated-above>
  $ export WSO2_APIM_USERNAME=admin
  $ export WSO2_APIM_PASSWORD=admin
  ````

- Start the service broker API using Ballerina:
   
  ````
  $ cd /path/to/wso2-apim-service-broker/
  $ ballerina run service wso2apim/cf/servicebroker/
  ````

- Find the IP address of the local machine and verify the catalog resource:

  ````
  $ curl -v http://<local-machine-ip>:9090/v2/catalog
  ...
  > GET /v2/catalog HTTP/1.1
  > Host: localhost:9090
  > User-Agent: curl/7.51.0
  > Accept: */*
  >
  < HTTP/1.1 200 OK
  < Content-Type: application/json
  < Content-Length: 486
  <
  ...
  {"services":[{"id":"wso2-apim-service-broker","name":"wso2-apim","description":"WSO2 API-M service broker for Pivotal CloudFoundry","tags":["wso2","api"],"requires":[],"bindable":true,"metadata":{"provider":{"name":"WSO2"},"listing":{"imageUrl":"https://upload.wikimedia.org/wikipedia/en/5/56/WSO2_Software_Logo.png"}},"plan_updateable":false,"plans":[{"id":"1","name":"default","description":"Default plan without any costs","max_storage_tb":0,"metadata":{"costs":[],"bullets":[]}}]}]}
  ````

- Create service broker using the following command:

  ````
  $ cf create-service-broker wso2-apim <broker-service-api-username> <broker-service-api-password> http://<local-machine-ip>:9090
  ````
  
- Find WSO2 API-M service name and plan name using the following command:

  ````
  $ cf marketplace
  Getting services from marketplace in org pcfdev-org / space pcfdev-space as admin...
  OK
  
  service                     plans             description
  wso2-apim                   default           WSO2 API-M service broker for Pivotal CloudFoundry
  local-volume                free-local-disk   Local service docs: https://github.com/cloudfoundry-incubator/local-volume-release/
  p-mysql                     512mb, 1gb        MySQL databases on demand
  p-rabbitmq                  standard          RabbitMQ is a robust and scalable high-performance multi-protocol messaging broker.
  p-redis                     shared-vm         Redis service to provide a key-value store
  
  TIP:  Use 'cf marketplace -s SERVICE' to view descriptions of individual plans of a given service.
  ````
  
- Create WSO2 API-M service instance using the following command:
 
  ````
  $ cf create-service wso2-apim default wso2-apim
  Creating service instance wso2-apim in org pcfdev-org / space pcfdev-space as admin...
  OK
  ````

- Deploy spring music application on CF by refering [this](https://github.com/cloudfoundry-samples/spring-music).

- List applications using the following command:

  ````
  $ cf apps
  Getting apps in org pcfdev-org / space pcfdev-space as admin...
  OK
    
  name           requested state   instances   memory   disk   urls
  spring-music   started           1/1         512M     512M   spring-music-doxastic-carucate.local.pcfdev.io
  ````
  
- Bind WSO2 API-M service to an application using the following command:

  ````
  parameters='{ "apiName":"foo", "apiVersion": "v1.0", "contextPath": "/foo", "serviceEndpoint": "http://foo.org", "serviceEndpointUsername": "admin", "serviceEndpointPassword": "admin"}'
  cf bind-service <application-name> wso2-apim -c ${parameters}
  Binding service wso2-apim to app spring-music in org pcfdev-org / space pcfdev-space as admin...
  OK
  TIP: Use 'cf restage spring-music' to ensure your env variable changes take effect
  ````

- Now login to WSO2 API-M store web application and verify the created API.

- Once verified, unbind WSO2 API-M service using the following command:

  ````
  $ cf unbind-service spring-music wso2-apim
  ````

## Installation

The installation provides steps for installing WSO2 API Manager service broker on an existing CloudFoundry environment.

- Clone this git repository:
  
  ````
  $ git clone https://github.com/imesh/wso2-apim-cf-service-broker.git
  ````

- Build broker service API using the following command:
  
  ````
  $ cd 
  $ ballerina build service wso2apim/cf/servicebroker/
  ````
  
- Create broker service API Docker image using the following command:

  ````
  $ docker_image=<repository>/<image-name>:<version>
  $ ballerina docker servicebroker.bsz -t ${docker_image} -y 
  ````
  
- Push broker service API Docker image to a Docker registry:

  ````
  $ docker push ${docker_image}
  ````
  
- Push broker service API to CloudFoundry as an application:

  ````
  $ cf push wso2-apim-service-broker-api --docker-image ${docker_image}
  ````

- Update WSO2 API Manager hostname and credentials in the following script and execute it to register an API client:

  ````
  $ ./register-api-client.sh
  ````

- Login to PCF Dev web console and add following environment variables to the service broker API application:

  ````
  WSO2_APIM_TOKEN_ENDPOINT=https://<wso2-apim-hostname>:8243/token
  WSO2_APIM_PUBLISHER_ENDPOINT=https://<wso2-apim-hostname>:9443/api/am/publisher
  WSO2_APIM_PUBLISHER_UI_URL=https://<wso2-apim-hostname>:9443/publisher/
  WSO2_APIM_CLIENT_ID=<client-id-generated-above>
  WSO2_APIM_CLIENT_SECRET=<client-secret-generated-above>
  WSO2_APIM_USERNAME=admin
  WSO2_APIM_PASSWORD=admin
  ````

- Create service broker using the following command:

  ````
  $ cf create-service-broker wso2-apim <broker-service-api-username> <broker-service-api-password> <broker-service-api-url>
  ````
  
- Find WSO2 API-M service name and plan name using the following command:

  ````
  $ cf marketplace
  Getting services from marketplace in org pcfdev-org / space pcfdev-space as admin...
  OK
  
  service                     plans             description
  wso2-apim                   default           WSO2 API-M service broker for Pivotal CloudFoundry
  local-volume                free-local-disk   Local service docs: https://github.com/cloudfoundry-incubator/local-volume-release/
  p-mysql                     512mb, 1gb        MySQL databases on demand
  p-rabbitmq                  standard          RabbitMQ is a robust and scalable high-performance multi-protocol messaging broker.
  p-redis                     shared-vm         Redis service to provide a key-value store
  
  TIP:  Use 'cf marketplace -s SERVICE' to view descriptions of individual plans of a given service.
  ````
  
- Create WSO2 API-M service instance using the following command:
 
  ````
  $ cf create-service wso2-apim default wso2-apim
  Creating service instance wso2-apim in org pcfdev-org / space pcfdev-space as admin...
  OK
  ````
  
- List applications using the following command:

  ````
  $ cf apps
  Getting apps in org pcfdev-org / space pcfdev-space as admin...
  OK
    
  name           requested state   instances   memory   disk   urls
  spring-music   started           1/1         512M     512M   spring-music-doxastic-carucate.local.pcfdev.io
  ````
  
- Bind WSO2 API-M service to an application using the following command:

  ````
  parameters='{ "apiName":"foo", "apiVersion": "v1.0", "contextPath": "/foo", "serviceEndpoint": "http://foo.org", "serviceEndpointUsername": "admin", "serviceEndpointPassword": "admin"}'
  cf bind-service <application-name> wso2-apim -c ${parameters}
  Binding service wso2-apim to app spring-music in org pcfdev-org / space pcfdev-space as admin...
  OK
  TIP: Use 'cf restage spring-music' to ensure your env variable changes take effect
  ````

- Now login to WSO2 API-M store web application and verify the created API.

- Once verified, unbind WSO2 API-M service using the following command:

  ````
  $ cf unbind-service spring-music wso2-apim
  ````
  
## License

Apache 2.0