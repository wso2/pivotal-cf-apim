#!/bin/bash

set -e
docker_image="imesh/wso2-apim-cf-service-broker"

echo "Building service..."
ballerina build service wso2apim/cf/servicebroker/

echo "Building docker image..."
ballerina docker servicebroker.bsz -t ${docker_image} -y
echo "Build completed!"