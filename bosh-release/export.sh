#!/bin/bash

set -e

echo "Exporting WSO2 API-M bosh release..."
bosh -e vbox create-release --tarball wso2apim-bosh-release.tar.gz
echo "DONE!"