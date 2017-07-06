# WSO2 API-M Client

This ballerina component provides functions for invoking WSO2 API-M Publisher API.

## Environment Variables
export WSO2_APIM_TOKEN_ENDPOINT=https://localhost:8243/token
export WSO2_APIM_PUBLISHER_ENDPOINT=https://127.0.0.1:9443/api/am/publisher/v0.11/apis
export WSO2_APIM_CLIENT_ID=PwvKkK9I44wiDbNiWuN7YfLboJIa
export WSO2_APIM_CLIENT_SECRET=xFxMy4lDpALFGf7yJFLSZDFACDMa
export WSO2_APIM_USERNAME=admin
export WSO2_APIM_PASSWORD=admin

## Register Client
curl -X POST -u admin:admin -H "Content-Type: application/json" -d @payload.json http://localhost:9763/client-registration/v0.11/register

## Generate Token
curl -k -d "grant_type=password&username=admin&password=admin&scope=apim:api_view apim:api_create apim:api_publish" -u ${client_id}:${client_secret} https://127.0.0.1:8243/token

## Create API
curl -v -k -H 'Content-Type: application/json' -H 'Authorization: Bearer ${token}' -d @pizzashack.json https://127.0.0.1:9443/api/am/publisher/v0.11/apis

## Publish API
curl -v -k -H 'Content-Type: application/json' -H 'Authorization: Bearer ${token}' https://127.0.0.1:9443/api/am/publisher/v0.11/apis/change-lifecycle?apiId=${api_id}&action=Publish

## Get APIs
curl -v -k -H 'Authorization: Bearer ${token}' https://127.0.0.1:9443/api/am/publisher/v0.11/apis
