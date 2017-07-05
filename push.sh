#!/bin/bash

set -e
docker_image="imesh/wso2-apim-cf-service-broker"
service_broker_api="wso2-apim-cf-broker-api"

echo "Pushing docker images..."
docker push ${docker_image}

cf push ${service_broker_api} --docker-image ${docker_image}
echo "Update process completed"