#!/bin/bash

curl -X POST -u admin:admin -H "Content-Type: application/json" -d '{
    "callbackUrl": "http://localhost/callback",
    "clientName": "wso2-apim-cf-service-broker",
    "tokenScope": "Production",
    "owner": "admin",
    "grantType": "password refresh_token",
    "saasApp": true
}' http://localhost:9763/client-registration/v0.11/register