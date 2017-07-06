import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.lang.system;
import ballerina.lang.strings;
import ballerina.utils;

function main (string[] args) {

    string tokenEndpoint = system:getEnv("WSO2_APIM_TOKEN_ENDPOINT");
    string username = system:getEnv("WSP2_APIM_USERNAME");
    string password = system:getEnv("WSO2_APIM_PASSWORD");
    string clientId = system:getEnv("WSO2_APIM_CLIENT_ID");
    string clientSecret = system:getEnv("WSO2_APIM_CLIENT_SECRET");
    string token = getAccessToken(tokenEndpoint, username, password, clientId, clientSecret);

    string publisherEndpoint = system:getEnv("WSO2_APIM_PUBLISHER_ENDPOINT");
    string serviceEndpoint = "http://foo.org/bar";
    createApi(publisherEndpoint, token, "foo", "v1.0", "/foo", serviceEndpoint, "admin", "admin");
}

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
    system:println(responseMessage);
    json response = messages:getJsonPayload(responseMessage);
    return strings:valueOf(response.access_token);
}

function createApi (string publisherEndpoint, string token, string apiName,
                    string apiVersion, string contextPath, string serviceEndpoint,
                    string serviceUsername, string servicePassword) {

    system:println("Creating API " + apiName + "...");

    message requestMessage = {};
    messages:setHeader(requestMessage, "Content-Type", "application/json");
    messages:setHeader(requestMessage, "Authorization", "Bearer " + token);

    json apiDef = {"paths":{"/order":{"post":{"x-auth-type":"Application & Application User","x-throttling-tier":"Unlimited","description":"Create a new Order","parameters":[{"schema":{"$ref":"#/definitions/Order"},"description":"Order object that needs to be added","name":"body","required":true,"in":"body"}],"responses":{"201":{"headers":{"Location":{"description":"The URL of the newly created resource.","type":"string"}},"schema":{"$ref":"#/definitions/Order"},"description":"Created."}}}},"/menu":{"get":{"x-auth-type":"Application & Application User","x-throttling-tier":"Unlimited","description":"Return a list of available menu items","parameters":[],"responses":{"200":{"headers":{},"schema":{"title":"Menu","properties":{"list":{"items":{"$ref":"#/definitions/MenuItem"},"type":"array"}},"type":"object"},"description":"OK."}}}}},"schemes":["https"],"produces":["application/json"],"swagger":"2.0","definitions":{"MenuItem":{"title":"Pizza menu Item","properties":{"price":{"type":"string"},"description":{"type":"string"},"name":{"type":"string"},"image":{"type":"string"}},"required":["name"]},"Order":{"title":"Pizza Order","properties":{"customerName":{"type":"string"},"delivered":{"type":"boolean"},"address":{"type":"string"},"pizzaType":{"type":"string"},"creditCardNumber":{"type":"string"},"quantity":{"type":"number"},"orderId":{"type":"integer"}},"required":["orderId"]}},"consumes":["application/json"],"info":{"title":"PizzaShackAPI","description":"This document describe a RESTFul API for Pizza Shack online pizza delivery store.\\n","license":{"name":"Apache 2.0","url":"http://www.apache.org/licenses/LICENSE-2.0.html"},"contact":{"email":"architecture@pizzashack.com","name":"John Doe","url":"http://www.pizzashack.com"},"version":"1.0.0"}};

    json payload = {
                       "name": apiName,
                       "description": "An API generated using CloudFoundry service broker for WSO2 API Manager.\r\n",
                       "context": contextPath,
                       "version": apiVersion,
                       "provider": "WSO2",
                       "apiDefinition": strings:valueOf(apiDef),
                       "wsdlUri": null,
                       "responseCaching": "Disabled",
                       "cacheTimeout": 300,
                       "destinationStatsEnabled": false,
                       "isDefaultVersion": false,
                       "type": "HTTP",
                       "transport":    [
                                       "http",
                                       "https"
                                       ],
                       "tags": ["pizza"],
                       "tiers": ["Unlimited"],
                       "maxTps":    {
                                        "sandbox": 5000,
                                        "production": 1000
                                    },
                       "visibility": "PUBLIC",
                       "visibleRoles": [],
                       "visibleTenants": [],
                       "endpointConfig": "{\"production_endpoints\":{\"url\":\"" + serviceEndpoint + "\",\"config\":null},\"sandbox_endpoints\":{\"url\":\"" + serviceEndpoint + "\",\"config\":null},\"endpoint_type\":\"http\"}",
                       "endpointSecurity":    {
                                                  "username": serviceUsername,
                                                  "type": "basic",
                                                  "password": servicePassword
                                              },
                       "gatewayEnvironments": "Production and Sandbox",
                       "sequences": [],
                       "subscriptionAvailability": null,
                       "subscriptionAvailableTenants": [],
                       "businessInformation":    {
                                                     "businessOwnerEmail": "support@wso2.com",
                                                     "technicalOwnerEmail": "support@wso2.com",
                                                     "technicalOwner": "WSO2",
                                                     "businessOwner": "WSO2"
                                                 },
                       "corsConfiguration":    {
                                                   "accessControlAllowOrigins": ["*"],
                                                   "accessControlAllowHeaders":       [
                                                                                      "authorization",
                                                                                      "Access-Control-Allow-Origin",
                                                                                      "Content-Type",
                                                                                      "SOAPAction"
                                                                                      ],
                                                   "accessControlAllowMethods":       [
                                                                                      "GET",
                                                                                      "PUT",
                                                                                      "POST",
                                                                                      "DELETE",
                                                                                      "PATCH",
                                                                                      "OPTIONS"
                                                                                      ],
                                                   "accessControlAllowCredentials": false,
                                                   "corsConfigurationEnabled": false
                                               }
                   };

    messages:setJsonPayload(requestMessage, payload);

    http:ClientConnector publisherApi = create http:ClientConnector(publisherEndpoint);
    message responseMessage = http:ClientConnector.post(publisherApi, "", requestMessage);
    system:println(responseMessage);
}

function setBasicAuthHeader (message m, string username, string password) {
    string encodedBasicAuthValue = utils:base64encode(username + ":" + password);
    messages:setHeader(m, "Authorization", "Basic " + encodedBasicAuthValue);
}