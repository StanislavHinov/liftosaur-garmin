import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class GlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        var h = dc.getHeight();
        dc.setColor(0xA48BFA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h / 4, Graphics.FONT_GLANCE, "LIFT LOG", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h * 3 / 4, Graphics.FONT_GLANCE, GlanceText.text(Application.Storage.getValue("glance")), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
