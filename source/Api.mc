import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

(:background)
class Api {
    var _apiKey;
    var _deviceId;

    function initialize(apiKey, deviceId) {
        _apiKey = apiKey;
        _deviceId = deviceId;
    }

    function setKey(apiKey) {
        _apiKey = apiKey;
    }

    function hasKey() {
        return _apiKey != null;
    }

    function request(desc, callback) {
        var method = Communications.HTTP_REQUEST_METHOD_GET;
        if (desc["method"] == :post) {
            method = Communications.HTTP_REQUEST_METHOD_POST;
        } else if (desc["method"] == :delete) {
            method = Communications.HTTP_REQUEST_METHOD_DELETE;
        }
        var options = {
            :method => method,
            :headers => Requests.headers(_apiKey, _deviceId, desc["method"]),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(Config.BASE_URL + desc["path"], desc["body"], options, new ApiCall(desc["path"], callback).method(:onResponse));
    }
}

(:background)
class ApiCall {
    var _path;
    var _callback;

    function initialize(path, callback) {
        _path = path;
        _callback = callback;
    }

    function onResponse(status, data) {
        var code = ErrorPolicy.errorField(data, "code");
        System.println("api " + _path + " -> " + status + (code == null ? "" : " " + code + ": " + ErrorPolicy.message(data)));
        _callback.invoke(status, data);
    }
}
