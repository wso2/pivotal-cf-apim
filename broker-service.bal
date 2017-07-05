import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.net.uri;
import ballerina.lang.system;

@http:config {basePath:"/v2"}
service<http> serviceBroker {

    @http:GET {}
    @http:Path {value:"/catalog"}
    resource catalog (message m) {

        json catalog = {"services":[
                                   {"id":"wso2-apim-service-broker",
                                       "name":"WSO2 API-M Service Broker",
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
                                                   "name":"Default Plan",
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

        string planId = uri:getQueryParam(m, "plan_id");
        string serviceId = uri:getQueryParam(m, "service_id");
        string operation = uri:getQueryParam(m, "operation");

        system:println("HTTP GET /service_instances/" + instanceId + "/last_operation");
        system:println("serviceId: " + serviceId + " planId: " + planId + " operation: " + operation);

        // TODO: Implement support for async operations
        message response = {};
        json payload = {"state":"succeeded", "description":""};
        messages:setJsonPayload(response, payload);
        reply response;
    }

    @http:PUT {}
    @http:Path {value:"/service_instances/{instanceId}"}
    resource putServiceInstance (message m, @http:PathParam {value:"instanceId"} string instanceId) {
        system:println("HTTP PUT /service_instances/" + instanceId);

        // TODO: Implement tenant provisioning logic
        message response = {};
        json payload = {
                           "dashboard_url":"http://wso2-apim-publisher/"
                       };
        messages:setJsonPayload(response, payload);
        http:setStatusCode(response, 201);
        reply response;
    }

    @http:PUT {}
    @http:Path {value:"/service_instances/{instanceId}/service_bindings/{bindingId}"}
    resource putServiceInstanceBinding (message m, @http:PathParam {value:"instanceId"} string instanceId,
                                        @http:PathParam {value:"bindingId"} string bindingId) {
        system:println("HTTP PUT /service_instances/" + instanceId + "/service_bindings/" + bindingId);

        // TODO: Implement API creation logic
        message response = {};
        json payload = {};
        messages:setJsonPayload(response, payload);
        reply response;
    }

    @http:DELETE {}
    @http:Path {value:"/service_instances/{instanceId}/service_bindings/{bindingId}"}
    resource deleteServiceInstanceBinding (message m, @http:PathParam {value:"instanceId"} string instanceId,
                                           @http:PathParam {value:"bindingId"} string bindingId) {
        system:println("HTTP DELETE /service_instances/" + instanceId + "/service_bindings/" + bindingId);

        // TODO: Implement API deletion logic
        message response = {};
        json payload = {};
        messages:setJsonPayload(response, payload);
        reply response;
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
