# WSO2 API Manager BOSH Release

A BOSH release for deploying WSO2 API Manager 2.1.0 with Analytics on BOSH Director.

## Quick Start Guide

1. Install [bosh v2][1], ruby, VirtualBox, mysql client (5.7) and docker.
2. Create a directory (say `apim`) and copy following binaries in to it. Make sure to have exact versions as they are used in the scripts.

 	    jdk-8u144-linux-x64.tar.gz  
        mysql-connector-java-5.1.24-bin.jar  
        Wso2am-2.1.0.zip WUM Updated pack 
        Wso2am-analytics-2.1.0.zip WUM Updated pack


3. Go inside that directory and clone [pivotal-cf-apim][2] repo.

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
        
5. Run deploy-all.sh script. You will be asked for superuser password in the middle.

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
        

[1]: http://bosh.io
[2]: https://github.com/bhathiya/pivotal-cf-apim
[image]: https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png



## References

* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)
