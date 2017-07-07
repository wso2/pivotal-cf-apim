package wso2apim.publisher.api.client;

import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.lang.system;
import ballerina.lang.strings;
import ballerina.lang.jsons;
import ballerina.utils;

function getAccessToken (string tokenEndpoint, string username, string password, string clientId, string clientSecret) (string) {

    system:println("Requesting access token...");

    message requestMessage = {};
    string requestPayload = "grant_type=password&username=" + username + "&password=" + password
                            + "&scope=apim:api_view apim:api_create apim:api_publish";
    messages:setStringPayload(requestMessage, requestPayload);

    setBasicAuthHeader(requestMessage, clientId, clientSecret);
    messages:setHeader(requestMessage, "Content-Type", "application/x-www-form-urlencoded");

    http:ClientConnector tokenApi = create http:ClientConnector(tokenEndpoint);
    message responseMessage = http:ClientConnector.post(tokenApi, "", requestMessage);

    if (http:getStatusCode(responseMessage) == 200) {
        json response = messages:getJsonPayload(responseMessage);
        system:println(response.access_token);
        return strings:valueOf(response.access_token);
    } else {
        system:println("Error: Could not acquire an access token!");
        system:println(messages:getStringPayload(responseMessage));
        return "";
    }
}

function createApi (string publisherEndpoint, string token, string apiName,
                    string apiVersion, string contextPath, string serviceEndpoint,
                    string serviceUsername, string servicePassword, string reference) (string apiId, string error) {

    system:println("Creating API " + apiName + "...");

    message requestMessage = {};
    messages:setHeader(requestMessage, "Content-Type", "application/json");
    messages:setHeader(requestMessage, "Authorization", "Bearer " + token);

    json apiDef = {"paths":{"/order":{"post":{"x-auth-type":"Application & Application User", "x-throttling-tier":"Unlimited", "description":"Create a new Order", "parameters":[{"schema":{"$ref":"#/definitions/Order"}, "description":"Order object that needs to be added", "name":"body", "required":true, "in":"body"}], "responses":{"201":{"headers":{"Location":{"description":"The URL of the newly created resource.", "type":"string"}}, "schema":{"$ref":"#/definitions/Order"}, "description":"Created."}}}}, "/menu":{"get":{"x-auth-type":"Application & Application User", "x-throttling-tier":"Unlimited", "description":"Return a list of available menu items", "parameters":[], "responses":{"200":{"headers":{}, "schema":{"title":"Menu", "properties":{"list":{"items":{"$ref":"#/definitions/MenuItem"}, "type":"array"}}, "type":"object"}, "description":"OK."}}}}}, "schemes":["https"], "produces":["application/json"], "swagger":"2.0", "definitions":{"MenuItem":{"title":"Pizza menu Item", "properties":{"price":{"type":"string"}, "description":{"type":"string"}, "name":{"type":"string"}, "image":{"type":"string"}}, "required":["name"]}, "Order":{"title":"Pizza Order", "properties":{"customerName":{"type":"string"}, "delivered":{"type":"boolean"}, "address":{"type":"string"}, "pizzaType":{"type":"string"}, "creditCardNumber":{"type":"string"}, "quantity":{"type":"number"}, "orderId":{"type":"integer"}}, "required":["orderId"]}}, "consumes":["application/json"], "info":{"title":"PizzaShackAPI", "description":"This document describe a RESTFul API for Pizza Shack online pizza delivery store.\\n", "license":{"name":"Apache 2.0", "url":"http://www.apache.org/licenses/LICENSE-2.0.html"}, "contact":{"email":"architecture@pizzashack.com", "name":"John Doe", "url":"http://www.pizzashack.com"}, "version":"1.0.0"}};

    json payload = {
                       "name":apiName,
                       "description":"An API generated using CloudFoundry service broker for WSO2 API Manager.\r\n" + reference,
                       "context":contextPath,
                       "version":apiVersion,
                       "provider":"WSO2",
                       "apiDefinition":strings:valueOf(apiDef),
                       "wsdlUri":null,
                       "responseCaching":"Disabled",
                       "cacheTimeout":300,
                       "destinationStatsEnabled":false,
                       "isDefaultVersion":false,
                       "type":"HTTP",
                       "transport":[
                                   "http",
                                   "https"
                                   ],
                       "tags": [],
                       "tiers":["Unlimited"],
                       "maxTps":{
                                    "sandbox":5000,
                                    "production":1000
                                },
                       "visibility":"PUBLIC",
                       "visibleRoles":[],
                       "visibleTenants":[],
                       "endpointConfig":"{\"production_endpoints\":{\"url\":\"" + serviceEndpoint + "\",\"config\":null},\"sandbox_endpoints\":{\"url\":\"" + serviceEndpoint + "\",\"config\":null},\"endpoint_type\":\"http\"}",
                       "endpointSecurity":{
                                              "username":serviceUsername,
                                              "type":"basic",
                                              "password":servicePassword
                                          },
                       "gatewayEnvironments":"Production and Sandbox",
                       "sequences":[],
                       "subscriptionAvailability":null,
                       "subscriptionAvailableTenants":[],
                       "businessInformation":{
                                                 "businessOwnerEmail":"support@wso2.com",
                                                 "technicalOwnerEmail":"support@wso2.com",
                                                 "technicalOwner":"WSO2",
                                                 "businessOwner":"WSO2"
                                             },
                       "corsConfiguration":{
                                               "accessControlAllowOrigins":["*"],
                                               "accessControlAllowHeaders":[
                                                                           "authorization",
                                                                           "Access-Control-Allow-Origin",
                                                                           "Content-Type",
                                                                           "SOAPAction"
                                                                           ],
                                               "accessControlAllowMethods":[
                                                                           "GET",
                                                                           "PUT",
                                                                           "POST",
                                                                           "DELETE",
                                                                           "PATCH",
                                                                           "OPTIONS"
                                                                           ],
                                               "accessControlAllowCredentials":false,
                                               "corsConfigurationEnabled":false
                                           }
                   };

    messages:setJsonPayload(requestMessage, payload);

    http:ClientConnector publisherApi = create http:ClientConnector(publisherEndpoint + "/v0.11/apis");
    message responseMessage = http:ClientConnector.post(publisherApi, "", requestMessage);
    if (http:getStatusCode(responseMessage) == 201) {
        system:println("API " + apiName + " created successfully");
        json response = messages:getJsonPayload(responseMessage);
        return strings:valueOf(response.id), "";
    } else {
        error = messages:getStringPayload(responseMessage);
        system:println("Error: Could not create API " + apiName);
        system:println(error);
        return "", error;
    }
}

function publishApi (string publisherEndpoint, string token, string apiId, string apiName) (boolean success, string error) {

    system:println("Publishing API [id] " + apiId + " [name] " + apiName + "...");

    message requestMessage = {};
    messages:setHeader(requestMessage, "Authorization", "Bearer " + token);
    http:ClientConnector publisherApi = create http:ClientConnector(publisherEndpoint + "/v0.11/apis/change-lifecycle?"
                                                                    + "apiId=" + apiId + "&action=Publish");
    message responseMessage = http:ClientConnector.post(publisherApi, "", requestMessage);
    if (http:getStatusCode(responseMessage) == 200) {
        system:println("API " + apiName + " published successfully");
        return true, "";
    } else {
        error = messages:getStringPayload(responseMessage);
        system:println("Error: Could not publish API " + apiName);
        system:println(error);
        return false, error;
    }
}

function deleteApi (string publisherEndpoint, string token, string apiId, string apiName) (boolean success, string error) {
    system:println("Deleting API [id] " + apiId + " [name] " + apiName + "...");

    message requestMessage = {};
    messages:setHeader(requestMessage, "Authorization", "Bearer " + token);

    http:ClientConnector publisherApi = create http:ClientConnector(publisherEndpoint + "/v0.11/apis/" + apiId);
    message responseMessage = http:ClientConnector.delete(publisherApi, "", requestMessage);
    if (http:getStatusCode(responseMessage) == 200) {
        system:println("API [id] " + apiId + " [name] " + apiName + " deleted successfully");
        return true, "";
    } else {
        error = messages:getStringPayload(responseMessage);
        system:println("Error: Could not delete API [id] " + apiId + " [name]" + apiName);
        system:println(error);
        return false, error;
    }
}

function getApiIdNameByReference(string publisherEndpoint, string token, string reference) (string apiId, string apiName, string error) {
    system:println("Finding API by reference " + reference + "...");

    message requestMessage = {};
    messages:setHeader(requestMessage, "Authorization", "Bearer " + token);

    http:ClientConnector publisherApi = create http:ClientConnector(publisherEndpoint + "/v0.11/apis/");
    message responseMessage = http:ClientConnector.get(publisherApi, "", requestMessage);
    system:println(responseMessage);

    if (http:getStatusCode(responseMessage) == 200) {
        json response = messages:getJsonPayload(responseMessage);
        int i = 0;
        while(i < jsons:getInt(response.list, "$.length()")) {
            var api = response.list[i];
            system:println("description = " + strings:valueOf(api.description));
            system:println("reference = " + reference);

            if(strings:contains(strings:valueOf(api.description), reference)) {
                return strings:valueOf(api.id), strings:valueOf(api.name), "";
            }
            i = i + 1;
        }
        return "", "", "";
    } else {
        error = messages:getStringPayload(responseMessage);
        system:println("Error: Could not retrieve APIs");
        system:println(error);
        return "", "", error;
    }
}

function setBasicAuthHeader (message m, string username, string password) {
    string encodedBasicAuthValue = utils:base64encode(username + ":" + password);
    messages:setHeader(m, "Authorization", "Basic " + encodedBasicAuthValue);
}