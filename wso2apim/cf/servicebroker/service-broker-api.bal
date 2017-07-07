package wso2apim.cf.servicebroker;

import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.lang.system;
import ballerina.lang.strings;
import wso2apim.publisher.api.client as wso2apimclient;

@http:config {basePath:"/v2"}
service<http> serviceBroker {

    string apiPublisherUiUrl = system:getEnv("WSO2_APIM_PUBLISHER_UI_URL");
    string tokenEndpoint = system:getEnv("WSO2_APIM_TOKEN_ENDPOINT");
    string username = system:getEnv("WSP2_APIM_USERNAME");
    string password = system:getEnv("WSO2_APIM_PASSWORD");
    string clientId = system:getEnv("WSO2_APIM_CLIENT_ID");
    string clientSecret = system:getEnv("WSO2_APIM_CLIENT_SECRET");
    string publisherEndpoint = system:getEnv("WSO2_APIM_PUBLISHER_ENDPOINT");

    @http:GET {}
    @http:Path {value:"/catalog"}
    resource catalog (message m) {

        system:println("HTTP GET /catalog");

        json catalog = {"services":[
                                   {"id":"wso2-apim-service-broker",
                                       "name":"wso2-apim",
                                       "description":"WSO2 API-M service broker for Pivotal CloudFoundry",
                                       "tags":["wso2", "api"],
                                       "requires":[],
                                       "bindable":true,
                                       "metadata":{
                                                      "provider":{
                                                                     "name":"WSO2"
                                                                 },
                                                      "listing":{
                                                                    "imageUrl":"https://upload.wikimedia.org/wikipedia/en/5/56/WSO2_Software_Logo.png"
                                                                }
                                                  },
                                       "plan_updateable":false,
                                       "plans":[
                                               {"id":"1",
                                                   "name":"default",
                                                   "description":"Default plan without any costs",
                                                   "max_storage_tb":0,
                                                   "metadata":{
                                                                  "costs":[],
                                                                  "bullets":[]
                                                              }
                                               }]
                                   }]};

        message response = {};
        messages:setJsonPayload(response, catalog);
        reply response;
    }

    @http:GET {}
    @http:Path {value:"/service_instances/{instanceId}/last_operation"}
    resource getLastOperation (message m, @http:PathParam {value:"instanceId"} string instanceId) {
        system:println("HTTP GET /service_instances/" + instanceId + "/last_operation");

        // TODO: Implement support for async operations
        message response = {};
        json payload = {"state":"succeeded", "description":""};
        messages:setJsonPayload(response, payload);
        reply response;
    }

    @http:PUT {}
    @http:Path {value:"/service_instances/{instanceId}"}
    resource putServiceInstance (message requestMessage, @http:PathParam {value:"instanceId"} string instanceId) {
        system:println("HTTP PUT /service_instances/" + instanceId);

        // TODO: Implement tenant provisioning logic
        message response = {};
        json payload = {
                           "dashboard_url": apiPublisherUiUrl
                       };
        messages:setJsonPayload(response, payload);
        http:setStatusCode(response, 201);
        reply response;
    }

    @http:PUT {}
    @http:Path {value:"/service_instances/{instanceId}/service_bindings/{bindingId}"}
    resource putServiceInstanceBinding (message requestMessage, @http:PathParam {value:"instanceId"} string instanceId,
                                        @http:PathParam {value:"bindingId"} string bindingId) {
        system:println("HTTP PUT /service_instances/" + instanceId + "/service_bindings/" + bindingId);

        json request = messages:getJsonPayload(requestMessage);
        json parameters = request.parameters;

        message responseMessage = {};
        if(parameters == null) {
            http:setStatusCode(responseMessage, 400);
            json error = { "error": "Parameters not found in request message" };
            messages:setJsonPayload(responseMessage, error);
            reply responseMessage;
        }

        if(parameters.apiName == null) {
            responseMessage = createErrorResponse("API name not found in parameters");
            reply responseMessage;
        }
        string apiName = strings:valueOf(parameters.apiName);

        if(parameters.apiVersion == null) {
            responseMessage = createErrorResponse("API version not found in parameters");
            reply responseMessage;
        }
        string apiVersion = strings:valueOf(parameters.apiVersion);

        if(parameters.contextPath == null) {
            responseMessage = createErrorResponse("Context path not found in parameters");
            reply responseMessage;
        }
        string contextPath = strings:valueOf(parameters.contextPath);

        if(parameters.serviceEndpoint == null) {
            responseMessage = createErrorResponse("Service endpoint not found in parameters");
            reply responseMessage;
        }
        string serviceEndpoint = strings:valueOf(parameters.serviceEndpoint);

        if(parameters.serviceEndpointUsername == null) {
            responseMessage = createErrorResponse("Service endpoint username not found in parameters");
            reply responseMessage;
        }
        string serviceEndpointUsername = strings:valueOf(parameters.serviceEndpointUsername);

        if(parameters.serviceEndpointPassword == null) {
            responseMessage = createErrorResponse("Service endpoint password not found in parameters");
            reply responseMessage;
        }
        string serviceEndpointPassword = strings:valueOf(parameters.serviceEndpointPassword);

        string token = wso2apimclient:getAccessToken(tokenEndpoint, username, password, clientId, clientSecret);
        string reference = createReference(bindingId);

        string apiId = "";
        string error = "";
        apiId, error = wso2apimclient:createApi(publisherEndpoint, token, apiName, apiVersion, contextPath, serviceEndpoint,
                                 serviceEndpointUsername, serviceEndpointPassword, reference);
        if (apiId == "") {
            json payload = { "error": error };
            http:setStatusCode(responseMessage, 400);
            messages:setJsonPayload(responseMessage, payload);
            reply responseMessage;
        }

        boolean success;
        success, error = wso2apimclient:publishApi(publisherEndpoint, token, apiId, apiName);
        if(!success) {
            json payload = { "error": error };
            http:setStatusCode(responseMessage, 400);
            messages:setJsonPayload(responseMessage, payload);
            reply responseMessage;
        }

        json payload = {};
        http:setStatusCode(responseMessage, 201);
        messages:setJsonPayload(responseMessage, payload);
        reply responseMessage;
    }

    @http:DELETE {}
    @http:Path {value:"/service_instances/{instanceId}/service_bindings/{bindingId}"}
    resource deleteServiceInstanceBinding (message requestMessage,
                                           @http:PathParam {value:"instanceId"} string instanceId,
                                           @http:PathParam {value:"bindingId"} string bindingId) {
        system:println("HTTP DELETE /service_instances/" + instanceId + "/service_bindings/" + bindingId);

        // Find API ID
        string apiId = "";
        string apiName = "";
        string error = "";
        string reference = createReference(bindingId);
        string token = wso2apimclient:getAccessToken(tokenEndpoint, username, password, clientId, clientSecret);

        message responseMessage = {};
        apiId, apiName, error = wso2apimclient:getApiIdNameByReference(publisherEndpoint, token, reference);
        if(apiId == "") {
            json payload = { "error": "Could not find API with binding id " + bindingId };
            http:setStatusCode(responseMessage, 404);
            messages:setJsonPayload(responseMessage, payload);
            reply responseMessage;
        }
        if(error != "") {
            json payload = { "error": error };
            http:setStatusCode(responseMessage, 400);
            messages:setJsonPayload(responseMessage, payload);
            reply responseMessage;
        }

        boolean success = false;
        success, error = wso2apimclient:deleteApi(publisherEndpoint, token, apiId, apiName);
        if(!success) {
            json payload = { "error": error };
            http:setStatusCode(responseMessage, 400);
            messages:setJsonPayload(responseMessage, payload);
            reply responseMessage;
        }

        json payload = {};
        http:setStatusCode(responseMessage, 200);
        messages:setJsonPayload(responseMessage, payload);
        reply responseMessage;
    }

    @http:DELETE {}
    @http:Path {value:"/service_instances/{instanceId}"}
    resource deleteServiceInstance (message m, @http:PathParam {value:"instanceId"} string instanceId) {
        system:println("HTTP DELETE /service_instances/" + instanceId);

        // TODO: Implement tenant un-provisioning logic

        message response = {};
        json payload = {};
        messages:setJsonPayload(response, payload);
        reply response;
    }
}
