# BOSH release for WSO2 API Manager deployment <br>pattern 1

This repository includes a BOSH release that can be used to deploy WSO2 API Manager 2.1.0 deployment pattern 1
configured to use a MySQL database on BOSH Director.

## Create and deploy the BOSH Release in BOSH Lite

### Prerequisites

Install the following software:

1. [BOSH CLI](https://bosh.io/docs/cli-v2.html)
2. [Docker](https://docs.docker.com/engine/installation/)
3. [VirtualBox](https://www.virtualbox.org/manual/ch02.html)
4. [WSO2 Update Manager](http://wso2.com/wum)
5. [Git client](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Quick Start Guide

1. Clone this Git repository
    ```
    git clone https://github.com/wso2/pivotal-cf-apim.git
    ```
    
2. Navigate to `pivotal-cf-apim/pattern-1/bosh-release` directory.

3. Add the following software distributions to the `dist` folder.

- [JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

- [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/5.1.html)

- WSO2 API Manager WUM updated product distribution

- WSO2 API Manager Analytics WUM updated product distribution

4. Execute the deploy.sh script.
   ```
   ./deploy.sh
   ```
   Executing this script will setup MySQL, BOSH environment and will deploy WSO2 API Manager 2.1.0 deployment pattern 1 on BOSH director.

5. Find the IP addresses of created VMs via the BOSH CLI and access the WSO2 API Manager Publisher, Store and Management Console via a web browser.
    ```
    bosh -e vbox vms
    ...
    
    Deployment 'wso2apim'
    
    Instance                                                 Process State  AZ  IPs          VM CID                                VM Type  
    wso2apim_1/da718160-7588-4594-a6fb-71aa73845a1b          running        -   10.244.15.2  45149778-a699-4030-7374-dd9613f43901  wso2apim-resource-pool  
    wso2apim_2/25e4cbc3-061d-48c9-ba33-5d71edb74f29          running        -   10.244.15.3  cb0408a3-50ed-4d7d-66ed-2ef50c1a2dd0  wso2apim-resource-pool  
    wso2apim_analytics/04d6fb22-82bd-42d6-9e93-a42ad5f6ec8d  running        -   10.244.15.4  f8bf7609-eeab-4700-4c08-70bf0edfd18a  wso2apim_analytics-resource-pool  
    
    3 vms
    
    Succeeded
    ...
    ```
    To ssh to the instance
    ```
    bosh -e vbox -d wso2apim ssh <instance_id>
    e.g. bosh -e vbox -d wso2apim ssh wso2apim_1/da718160-7588-4594-a6fb-71aa73845a1b
    ```
    Access the Publisher, Store and Management Console
    ```
    WSO2 API Manager Publisher: https://10.244.15.2:9443/publisher
    WSO2 API Manager Store: https://10.244.15.2:9443/store
    WSO2 API Manager Management Console: https://10.244.15.2:9443/carbon/
    ```

# Additional Info

Structure of the files of this repository will be as below :
```
└── bosh-release
    ├── config
    ├── dbscripts
    ├── deployment
    ├── dist
    ├── jobs
    ├── packages
    ├── src
    ├── create.sh
    ├── deploy.sh
    ├── export.sh
    ├── README.md
    ├── undeploy.sh
    └── wso2apim-manifest.yml
```
To know more about BOSH CLI commands to create a BOSH environment, create a bosh release and upload, refer deploy.sh script.

## References

* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)
