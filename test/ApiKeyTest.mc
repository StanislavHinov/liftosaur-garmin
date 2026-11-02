import Toybox.Lang;
import Toybox.Test;

(:test)
function apiKeyPrefersSettingOverBuiltIn(logger as Test.Logger) as Boolean {
    Test.assertEqual(ApiKey.pick("lftsk_phone", "lftsk_built"), "lftsk_phone");
    Test.assertEqual(ApiKey.pick("  lftsk_phone \n", ""), "lftsk_phone");
    Test.assertEqual(ApiKey.pick("", "lftsk_built"), "lftsk_built");
    Test.assertEqual(ApiKey.pick(null, "lftsk_built"), "lftsk_built");
    Test.assert(ApiKey.pick("   ", "") == null);
    Test.assert(ApiKey.pick(null, null) == null);
    return true;
}

(:test)
function apiKeyRejectsSpacesAndLineBreaksInside(logger as Test.Logger) as Boolean {
    // A line break inside would end up in the Authorization header.
    Test.assert(ApiKey.pick("lftsk_ab\r\nX-Other: 1", "") == null);
    Test.assert(ApiKey.pick("lftsk_a b", "") == null);
    Test.assertEqual(ApiKey.pick("lftsk_a b", "lftsk_built"), "lftsk_built");
    Test.assertEqual(ApiKey.pick(" lftsk_ok_1-2 ", ""), "lftsk_ok_1-2");
    return true;
}
