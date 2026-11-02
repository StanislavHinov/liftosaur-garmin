import Toybox.Lang;
import Toybox.Test;

(:test)
function smokeConfigHasBaseUrl(logger as Test.Logger) as Boolean {
    Test.assertEqual(Config.BASE_URL, "https://www.liftosaur.com/api/v1");
    return true;
}
