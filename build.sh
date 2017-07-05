#!/bin/bash

set -e
docker_image="imesh/wso2-apim-cf-service-broker"

echo "Building service..."
ballerina build service broker-service.bal

echo "Building docker image..."
ballerina docker broker-service.bsz -t ${docker_image} -y
echo "Build completed!"