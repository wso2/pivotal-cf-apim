# Pivotal Cloud Foundry Resources for WSO2 API Manager

This repository contains resources required to build and install WSO2 API Manager in a Pivotal Cloud Foundry (PCF) environment. This document provides instructions you need to follow in order to deploy a WSO2 API Manager setup on PCF.

## Prerequisites
Before starting the installation process, ensure that the following prerequisites are completed:
- A pre-configured Pivotal environment: For more information on the process for setting up the Pivotal environment on AWS, Azure, and GCP, see the documentation provided by Pivotal in [Architecture and Installation Overview](https://docs.pivotal.io/pivotalcf/2-4/installing/index.html).
- An SQL Database (MySQL or MS SQL): This database should contain the tables required to run API Manager. The database schema required to populate the tables can be found within the <APIM_HOME>/dbscripts/ directory, where <APIM_HOME> refers to the [API Manager Binary](https://wso2.com/api-management/).
- BOSH [CLI](https://bosh.io/docs/cli-v2/).
- PCF Tile Generator [CLI](https://docs.pivotal.io/tiledev/2-3/tile-generator.html).

## Setting up for BOSH Release
The first step in running API Manager on PCF is creating a BOSH release. The following set of instructions should be followed in this process:
1. Clone the PCF API Manager repository on GitHub by issuing the following command.
    ```bash
    git clone https://github.com/wso2/pivotal-cf-apim.git
    ```
    API Manager contains five main components named Publisher, Store, Gateway, Traffic Manager, and Key Manager. In a stand-alone APIM setup, these components are deployed in a single server. However, in a typical production setup, they need to be deployed in separate servers for better performance. Installing and configuring each or selected component/s in different servers is known as a distributed setup.
    
    There are multiple ways in which these distributed setups can be arranged. These are known as [Deployment Patterns](https://docs.wso2.com/display/AM260/Deployment+Patterns#DeploymentPatterns-WSO2APIManagerdeploymentpatterns). The PCF resources for API Manager currently support Pattern 1 and Pattern 1.
        
    The Deployment Architecture for Pattern 1 is as follows:
    
    ![pattern-1](images/pattern-1.png "Pattern 1")
    
2. Add distributions required to run Pattern 1 as follows:
    1. Navigate to the `pattern-1` directory by issuing the following command.
        ```bash
        cd pivotal-cf-apim/pattern-1
        ls 
        ```
        Observe that there are two subdirectories named `bosh-release` and `tile` within this directory.
    2. Navigate into the `bosh-release` directory to view all of the resources required to deploy API Manager Pattern 1 on PCF.
    3. To deploy Pattern 1, add the following files to the `dist` subdirectory inside the `bosh-deployment` directory.

        * [mssql-jdbc-7.0.0.jre8.jar](https://www.microsoft.com/en-us/download/details.aspx?id=57175)
        * [mysql-connector-java-5.1.45-bin.jar](https://dev.mysql.com/downloads/connector/j/)
        * [OpenJDK8U-jdk_x64_linux_hotspot_8u192b12.tar.gz](https://adoptopenjdk.net/archive.html)
        * [wso2am-2.6.0.zip](https://wso2.com/api-management/install/)
        * [wso2is-km-5.7.0.zip](https://wso2.com/api-management/install/key-manager/)
        
        JDBC Drivers for MySQL and MS SQL are added into the `dist` directory to add flexibility to the deployment. The tile cannot be changed once created, as the tile is immutable. However, options to switch between different databases can be provided.
                
3. Create the BOSH release
    
    In order to create the BOSH release, the resource provides two scripts with the deployment. The scripts must be run in the following order:
    ```bash
    ./create.sh
    ```
    
    This may take up to 20 minutes. After the build is complete, a bosh-release is completed in the root of the `bosh-deployment` directory.  This release pack is named `wso2am-2.6.0-bosh-release.tgz`.
    
## Building the Pivotal Tile for API Manager
1. Add the [routing-release](https://github.com/cloudfoundry/routing-release/releases/tag/0.178.0) provided by PCF to the root of the `tile` directory. This delivers HTTP and TCP routing for Cloud Foundry.
2. Copy the bosh release from the `bosh-release` directory into the `tile` directory by issuing the following command.
    ```bash
    cd bosh-release
    mv wso2am-2.6.0-bosh-release.tgz ../tile
    cd ../tile
    ```
3. Run the build script to build the tile by issuing the following command.
    ```bash
    ./build.sh
    ```
    The build process takes up to 5 minutes. After the build is complete, a tile named `wso2apim-tile-0.0.1.pivotal` is created in the root of the `/tile/product` directory.
    
## Install API Manager in PCF
1. Log in to PCF Ops Manager and upload the tile built by clicking **Import a Product**.
2. After the tile is uploaded, add the tile to the PCF environment by clicking the + icon next to it.
3. After the tile is added to the environment, click on the **API Manager** tile in the PCF environment to add configurations to the setup.
    ![API-Manager](images/new-tile.png "API Manager Tile")
4. Set up the API Manager tile.
    1. AZ and Network Assignments Page:
        ![az-network-assignments](images/az-assignment.png "AZs and Network Assignments")
        * Place singleton jobs in: Select the AZ in which the API Manager VM needs to run. The broker runs as a singleton job
        * Balance other jobs in: Select any combination of AZs.
        * Network: Select pcf-pas-network
        
        Click Save.
    2. Registry Database Connection Information:
        * **JDBC URL**:
            * **MySQL**: `jdbc:mysql://<hostname>:<port>/<db_name>?autoReconnect=true&amp;useSSL=false`
            * **MS SQL**: `jdbc:sqlserver://<hostname>:<port>;databaseName=<db_name>;`
        * **Driver Class Name**: Select the class name of the JDBC driver relevant to the database being used.
        * **Validation Query**: `SELECT 1`
        * **Username**: Username for database
        * **Password**: Password for database
        
        Click Save.
    3. User Management Database Connection Information:
        * **JDBC URL**:
            * **MySQL**: `jdbc:mysql://<hostname>:<port>/<db_name>?autoReconnect=true&amp;useSSL=false`
            * **MS SQL**: `jdbc:sqlserver://<hostname>:<port>;databaseName=<db_name>;`
        * **Driver Class Name**: Select the class name of the JDBC driver relevant to the database being used.
        * **Validation Query**: `SELECT 1`
        * **Username**: Username for database
        * **Password**: Password for database
            
            Click Save.
    4. API Manager Database Connection Information:
        * **JDBC URL**:
            * **MySQL**: `jdbc:mysql://<hostname>:<port>/<db_name>?autoReconnect=true&amp;useSSL=false`
            * **MS SQL**: `jdbc:sqlserver://<hostname>:<port>;databaseName=<db_name>;`
        * **Driver Class Name**: Select the class name of the JDBC driver relevant to the database being used.
        * **Validation Query**: `SELECT 1`
        * **Username**: Username for database
        * **Password**: Password for database
        
        Click Save.
    5. API Manager - Analytics Clustering Database connection information
        * **JDBC URL**:
            * **MySQL**: `jdbc:mysql://<hostname>:<port>/<db_name>?autoReconnect=true&useSSL=false`
            * **MS SQL**: `jdbc:sqlserver://<hostname>:<port>;databaseName=<db_name>;`
        * **Driver Class Name**: Select the class name of the JDBC driver relevant to the database being used.
        * **Validation Query**: `SELECT 1`
        * **Username**: Username for database
        * **Password**: Password for database
        
        Note that the JDBC URL for MySQL does not contain `&amp;`. Instead, it indicates the `&` symbol. This is due to the fact that the first two configurations save the configuration data in XML format, and `&amp;` is used as an escape character. However, this configuration stores its data in YAML and therefore, an escape character is not required.
        
        Click Save.
        
    6. Return to the **Installation Dashboard** in Ops Manager and click **Review Pending Changes**.
        ![review-changes](images/review-changes.png "Review Pending Changes")
    7. Select the checkbox for API Manager and click **Apply Changes**.
        ![apply-changes](images/apply-changes.png "Apply Changes")
        
        The installation process may take around 25 minutes. After the installation is complete, the management console, publisher, and store can be accessed via the following URLs where domain_name refers to the **domain name** of the PCF environment.
        
        * ``https://wso2apim.sys.<domain_name>/carbon/``
        * ``https://wso2apim.sys.<domain_name>/publisher/``
        * ``https://wso2apim.sys.<domain_name>/store/``
