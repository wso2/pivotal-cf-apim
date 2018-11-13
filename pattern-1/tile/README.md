# WSO2 API Manager Pivotal Cloud Foundry Tile

This repository includes a Cloud Foundry Tile for deploying WSO2 API Manager 2.6.0 on BOSH via Pivotal Ops Manager. 

## Quick Start

1. Clone WSO2 API Manager BOSH release repository and export BOSH release:

   ```
   git clone https://github.com/imesh/wso2-apim-bosh-release.git
   cd wso2-apim-bosh-release
   ./export.sh
   ```
2. Copy WSO2 API Manager BOSH release tar.gz file to the root folder of this tile project.

3. Build the tile using the below command:

   ```
   tile build --cache cache/
   ```

4. Upload the product/wso2apim-tile-<versiom>.pivotal file to Pivotal Ops Manager using [Ops Manager CLI](https://github.com/pivotal-cf/om) and execute a deployment:

    ```
    om -t {ops-manager-url} -u {username} -p {password} upload-product -p product/wso2apim-tile-{version}.pivotal
    ```
