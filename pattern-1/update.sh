#!/usr/bin/env bash
# ----------------------------------------------------------------------------
#
# Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------

# exit immediately if a command exits with a non-zero status
set -e

echo "Removing BLOB cache"
rm -rf ~/.bosh/cache/
rm -rf ~/.bosh/tmp/
> bosh-release/config/blobs.yml
rm -rf bosh-release/blobs
rm -rf bosh-release/.dev_builds

echo "Generating BOSH release..."
cd bosh-release
/bin/bash create.sh

echo "Moving BOSH release into tile directory"
mv wso2am-2.6.0-bosh-release.tgz ../tile
cd ../tile

echo "Building tile"
if [ -e cache/wso2_apim.tgz ]
then
    rm cache/wso2_apim.tgz
fi
/bin/bash build.sh
