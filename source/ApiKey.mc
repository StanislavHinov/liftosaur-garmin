import Toybox.Application;
import Toybox.Lang;

// The key comes from the app setting in Garmin Connect; a developer build may carry one built in.
(:background)
module ApiKey {
    function current() {
        var setting = null;
        try {
            setting = Application.Properties.getValue("apiKey");
        } catch (e) {
            setting = null;
        }
        return pick(setting, Application.loadResource(Rez.Strings.ApiKey));
    }

    function pick(setting, builtIn) {
        var s = valid(trim(setting));
        return s != null ? s : valid(trim(builtIn));
    }

    // A key with a space, line break or control character inside is mistyped, and a line break
    // would end up in the Authorization header.
    function valid(key) {
        if (key == null) {
            return null;
        }
        var chars = key.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i].toNumber();
            if (c <= 32 || c == 127) {
                return null;
            }
        }
        return key;
    }

    // Pasted keys often carry spaces or a line break; null when nothing is left.
    function trim(value) {
        if (value == null) {
            return null;
        }
        var chars = value.toString().toCharArray();
        var start = 0;
        var end = chars.size();
        while (start < end && chars[start].toNumber() <= 32) {
            start++;
        }
        while (end > start && chars[end - 1].toNumber() <= 32) {
            end--;
        }
        return start == end ? null : value.toString().substring(start, end);
    }
}
