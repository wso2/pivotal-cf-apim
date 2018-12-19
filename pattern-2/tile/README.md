# WSO2 API Manager Pivotal Cloud Foundry Tile

This repository includes a Cloud Foundry Tile for deploying WSO2 API Manager 2.6.0 on BOSH via Pivotal Ops Manager.

## Quick Start Guide

1. Clone WSO2 API Manager BOSH release repository and export BOSH release:

   ```
   git clone https://github.com/wso2/pivotal-cf-apim.git
   cd pivotal-cf-apim/pattern-2/bosh-release/
   ./export.sh
   ```
2. Copy WSO2 API Manager BOSH release tar.gz file to the root of the tile folder under pattern-2.

    ```
    cp wso2am-2.6.0-bosh-release.tgz ../tile/
    ```

3. Build the tile by running the build script from the root of the tile directory.

   ```
   cd ../tile/
   ./build.sh
   ```

4. Upload the product/wso2apim-tile-<versiom>.pivotal file to Pivotal Ops Manager using [Ops Manager CLI](https://github.com/pivotal-cf/om) and execute a deployment:

    ```
    om -t {ops-manager-url} -u {username} -p {password} upload-product -p product/wso2apim-tile-{version}.pivotal
    ```

## How to use Identity Server as Key Manager instead of API-M in-built key manager

  1. In the tile.yaml, under `jobs:` rename the `keymanager` job, as `wso2is_km`.

```
    ...
    - name: wso2is_km
      instances: 2
      templates:
      - name: wso2is_km
        release: wso2am-release
    ...
```
  2. Follow the [Quick Start Guide](https://github.com/wso2/pivotal-cf-apim/tree/2.6.x/pattern-2/tile#quick-start-guide) above.
