package wso2apim.cf.servicebroker;

import ballerina.net.http;
import ballerina.lang.messages;

function createErrorResponse(string errorMessage) (message) {
    message responseMessage = {};
    http:setStatusCode(responseMessage, 400);
    json error = { "error": errorMessage };
    messages:setJsonPayload(responseMessage, error);
    return responseMessage;
}