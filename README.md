# CloudFoundry Service Broker for WSO2 API Manager

This repository contains CloudFoundry service broker for WSO2 API Manager. The service broker API

## Getting Started

- Build broker service API using the following command:
  
  ````
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
  $ cf push wso2-apim- --docker-image ${docker_image}
  ````
  
- Create service broker using the following command:

  ````
  $ cf create-service-broker wso2-apim <username> <password> <broker-service-api-url>
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
  
## License

Apache 2.0