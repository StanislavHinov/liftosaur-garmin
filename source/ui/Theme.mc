import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Colors from the Liftosaur Apple Watch app (LiftosaurColor.swift).
module Theme {
    const BG = 0x000000;
    const TEXT = 0xFFFFFF;
    const CARD = 0x252034;
    const BOX = 0x332D42;
    const PILL_GREY = 0x393248;
    const DOT_OFF = 0x453D58;
    const PURPLE = 0x8356F6;
    const PURPLE_LIGHT = 0xA48BFA;
    const GREEN = 0x2BDC9B;
    const ORANGE = 0xFFB86B;
    const YELLOW = 0xFFD820;
    const RED = 0xFF8066;
    const GREY = 0xA4B0BC;
    // Get-ready countdown, apart from the purple work clock (as in the Apple Watch app).
    const READY = 0xFFDD7E;
    const READY_TRACK = 0x474431;

    // Layout sizes are designed for the 390 px screen.
    function px(dc, n) {
        return (n * dc.getWidth() / 390.0).toNumber();
    }

    function clear(dc) {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(TEXT, BG);
        dc.clear();
    }

    function center(dc, y, font, text, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function twoTone(dc, y, font, a, colorA, b, colorB) {
        var wa = dc.getTextWidthInPixels(a, font);
        var x = (dc.getWidth() - wa - dc.getTextWidthInPixels(b, font)) / 2;
        dc.setColor(colorA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, a, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(colorB, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + wa, y, font, b, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function fit(dc, text, font, maxWidth) {
        var s = text;
        while (s.length() > 1 && dc.getTextWidthInPixels(s, font) > maxWidth) {
            s = s.substring(0, s.length() - 1);
        }
        return s;
    }

    // Font sets for the stacked screens, largest first: [big, number, small].
    const TIERS = [
        [Graphics.FONT_MEDIUM, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_TINY],
        [Graphics.FONT_MEDIUM, Graphics.FONT_NUMBER_MILD, Graphics.FONT_TINY],
        [Graphics.FONT_SMALL, Graphics.FONT_NUMBER_MILD, Graphics.FONT_XTINY],
        [Graphics.FONT_TINY, Graphics.FONT_LARGE, Graphics.FONT_XTINY],
        [Graphics.FONT_XTINY, Graphics.FONT_MEDIUM, Graphics.FONT_XTINY]
    ];

    // Height of digits and capitals: the ascent without the font's internal leading.
    function capH(font) {
        return (Graphics.getFontAscent(font) * 0.72).toNumber();
    }

    // Usable width at height y; the round screen narrows towards the top and bottom.
    function chord(dc, y) {
        if (System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_ROUND) {
            return dc.getWidth();
        }
        return Layout.chord(dc.getWidth() / 2, dc.getHeight() / 2, y);
    }

    // Text drawn with its top at y, so a row is as tall as the font ascent.
    function textAt(dc, y, font, text, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function pillH(font) {
        return capH(font) * 2 + 4;
    }

    function pillW(dc, label, font) {
        var h = pillH(font);
        var w = (dc.getTextWidthInPixels(label, font) + h * 1.4).toNumber();
        return w < h * 2.6 ? (h * 2.6).toNumber() : w;
    }

    // A label pill sized from its font, centered on the screen; y is the pill center.
    function pill(dc, y, label, color, font) {
        pillAt(dc, dc.getWidth() / 2, y, label, color, font);
    }

    function pillAt(dc, cx, y, label, color, font) {
        var h = pillH(font);
        var w = pillW(dc, label, font);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - w / 2, y - h / 2, w, h, h / 2);
        dc.setColor(TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, font, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // The Apple Watch log button: a purple pill with a drawn check mark (the font has no check glyph).
    function checkPill(dc, cx, y, h) {
        var w = (h * 2.4).toNumber();
        dc.setColor(PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - w / 2, y - h / 2, w, h, h / 2);
        var s = h * 0.24;
        dc.setColor(TEXT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(h / 9 > 2 ? h / 9 : 2);
        dc.drawLine(cx - s * 1.1, y, cx - s * 0.3, y + s * 0.8);
        dc.drawLine(cx - s * 0.3, y + s * 0.8, cx + s * 1.2, y - s * 0.8);
        dc.setPenWidth(1);
    }

    // A heart of half-width s centered at (cx, cy); the font has no heart glyph.
    function heart(dc, cx, cy, s) {
        dc.setColor(RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - s / 2, cy - s / 4, s / 2 + 1);
        dc.fillCircle(cx + s / 2, cy - s / 4, s / 2 + 1);
        dc.fillPolygon([[cx - s - 1, cy - s / 8], [cx + s + 1, cy - s / 8], [cx, cy + s]]);
    }

    function boxH(numFont, smallFont) {
        return capH(numFont) + capH(smallFont) * 2;
    }

    function boxW(dc, text, unit, numFont, smallFont) {
        var w = dc.getTextWidthInPixels(text, numFont);
        var min = dc.getTextWidthInPixels("88", numFont);
        if (w < min) {
            w = min;
        }
        if (unit != null) {
            w += dc.getTextWidthInPixels(unit, smallFont);
        }
        return w + capH(smallFont) * 2;
    }

    function box(dc, x, y, w, h, text, unit, color, selected, numFont, smallFont) {
        var r = h / 5;
        dc.setColor(BOX, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, r);
        if (selected) {
            var pen = h / 18 > 2 ? h / 18 : 2;
            dc.setColor(PURPLE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(pen);
            dc.drawRoundedRectangle(x + pen / 2, y + pen / 2, w - pen, h - pen, r);
            dc.setPenWidth(1);
        }
        var textW = dc.getTextWidthInPixels(text, numFont);
        var unitW = unit == null ? 0 : dc.getTextWidthInPixels(unit, smallFont);
        var tx = x + (w - textW - unitW) / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(tx, y + h / 2, numFont, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        if (unit != null) {
            // Unit sits on the number's baseline.
            var base = y + h / 2 + capH(numFont) / 2;
            dc.drawText(tx + textW, base - Graphics.getFontAscent(smallFont), smallFont, unit, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function card(dc, x, y, w, h) {
        dc.setColor(CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, px(dc, 20));
    }

    // Dots of radius r with gaps of 3r, squeezed so the row never passes 40% of the screen width.
    function dotGap(dc, count, r) {
        var gap = r * 3;
        var maxWidth = dc.getWidth() * 0.4;
        if (count > 1 && (count - 1) * gap > maxWidth) {
            gap = (maxWidth / (count - 1)).toNumber();
        }
        return gap;
    }

    function dotsWidth(dc, count, r) {
        return count == 0 ? 0 : (count - 1) * dotGap(dc, count, r) + 2 * r;
    }

    function dots(dc, x, y, sets, current, r) {
        var gap = dotGap(dc, sets.size(), r);
        for (var i = 0; i < sets.size(); i++) {
            var cx = x + r + i * gap;
            if (i == current) {
                dc.setColor(TEXT, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(r / 2 > 2 ? r / 2 : 2);
                dc.drawCircle(cx, y, r - 1);
                dc.setPenWidth(1);
            } else {
                dc.setColor(sets[i]["completed"] != null ? GREEN : DOT_OFF, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, y, r);
            }
        }
    }

    // A ring at the screen edge: the track in full, and an arc from 12 o'clock covering fraction clockwise.
    function ring(dc, fraction, color, track) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var pen = px(dc, 9);
        var r = cx - pen / 2 - 1;
        dc.setPenWidth(pen);
        dc.setColor(track, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        var sweep = (360 * fraction).toNumber();
        if (sweep > 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            if (sweep >= 360) {
                dc.drawCircle(cx, cy, r);
            } else {
                dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, (450 - sweep) % 360);
            }
        }
        dc.setPenWidth(1);
    }

    // The arc starts at 12 o'clock and shrinks clockwise as the rest runs out.
    function restRing(dc, fraction, over) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var pen = px(dc, 9);
        var r = cx - pen / 2 - 1;
        dc.setPenWidth(pen);
        dc.setColor(over ? GREEN : CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        var sweep = (360 * fraction).toNumber();
        if (!over && sweep > 0) {
            dc.setColor(PURPLE, Graphics.COLOR_TRANSPARENT);
            if (sweep >= 360) {
                dc.drawCircle(cx, cy, r);
            } else {
                dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, (450 - sweep) % 360);
            }
        }
        dc.setPenWidth(1);
    }

    function icon(dc, y) {
        var bmp = WatchUi.loadResource(Rez.Drawables.LauncherIcon);
        dc.drawBitmap((dc.getWidth() - bmp.getWidth()) / 2, y - bmp.getHeight() / 2, bmp);
    }

    // A round − or + button for touch; the font has no minus glyph, so both are drawn.
    function stepButton(dc, cx, cy, r, plus) {
        dc.setColor(PILL_GREY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        var s = r / 2;
        var t = r / 6 > 2 ? r / 6 : 2;
        dc.setColor(TEXT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - s, cy - t / 2, s * 2, t);
        if (plus) {
            dc.fillRectangle(cx - t / 2, cy - s, t, s * 2);
        }
    }

    // Touch screens open the menu by holding the screen; other watches by holding Up.
    function menuHint() {
        return System.getDeviceSettings().isTouchScreen ? "Hold screen for menu" : "Hold UP for menu";
    }

    // Rows: [:big, text, color], [:small, text, color], [:pill, label, color], [:value, text, color, buttons?], [:icon], [:badge];
    // the rows between [:card] and [:end] sit on a card.
    // Returns [ys, heights, tier] so callers can add tap targets.
    function drawRows(dc, rows) {
        var h = dc.getHeight();
        var top = (h * 0.1).toNumber();
        var bottom = h - top;
        for (var t = 0; t < TIERS.size(); t++) {
            var tier = TIERS[t];
            var heights = [];
            for (var i = 0; i < rows.size(); i++) {
                heights.add(rowH(rows[i], tier));
            }
            var gap = capH(tier[2]) * 3 / 4;
            var ys = Layout.stack(heights, gap, top, bottom);
            var fits = Layout.total(heights, gap) <= bottom - top && rowsFit(dc, rows, tier, ys, heights);
            if (fits || t == TIERS.size() - 1) {
                drawStack(dc, rows, tier, ys, heights);
                return [ys, heights, tier];
            }
        }
    }

    function rowH(row, tier) {
        var kind = row[0];
        if (kind == :big) {
            return Graphics.getFontAscent(tier[0]);
        }
        if (kind == :small) {
            return Graphics.getFontAscent(tier[2]);
        }
        if (kind == :pill || kind == :badge) {
            return pillH(tier[2]);
        }
        if (kind == :value) {
            return boxH(tier[1], tier[2]);
        }
        if (kind == :icon) {
            return WatchUi.loadResource(Rez.Drawables.LauncherIcon).getHeight();
        }
        return capH(tier[2]) / 2;
    }

    // Width a row may use: the narrower end of the row, less a margin, or the card's inside.
    function rowRoom(dc, ys, heights, i, card) {
        if (card != null) {
            return card[1] - capH(TIERS[0][2]);
        }
        var a = chord(dc, ys[i]);
        var b = chord(dc, ys[i] + heights[i]);
        return (a < b ? a : b) - capH(TIERS[0][2]);
    }

    // [x, width, top, bottom] of the card that starts at row i.
    function cardAt(dc, rows, ys, heights, i) {
        var j = i;
        while (j < rows.size() && rows[j][0] != :end) {
            j++;
        }
        var bottom = j < rows.size() ? ys[j] + heights[j] : ys[i] + heights[i];
        var a = chord(dc, ys[i]);
        var b = chord(dc, bottom);
        var w = ((a < b ? a : b) * 0.92).toNumber();
        return [(dc.getWidth() - w) / 2, w, ys[i], bottom];
    }

    function rowsFit(dc, rows, tier, ys, heights) {
        var card = null;
        for (var i = 0; i < rows.size(); i++) {
            var kind = rows[i][0];
            if (kind == :card) {
                card = cardAt(dc, rows, ys, heights, i);
            } else if (kind == :end) {
                card = null;
            } else if (kind == :big || kind == :small) {
                var font = kind == :big ? tier[0] : tier[2];
                if (dc.getTextWidthInPixels(rows[i][1], font) > rowRoom(dc, ys, heights, i, card)) {
                    return false;
                }
            } else if (kind == :value) {
                // [:value, text, color, true] leaves room for − and + buttons beside the box.
                var buttons = rows[i].size() > 3 && rows[i][3] == true ? boxH(tier[1], tier[2]) * 2 : 0;
                if (boxW(dc, rows[i][1], null, tier[1], tier[2]) + buttons > rowRoom(dc, ys, heights, i, card)) {
                    return false;
                }
            }
        }
        return true;
    }

    function drawStack(dc, rows, tier, ys, heights) {
        var card = null;
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i];
            var kind = row[0];
            var y = ys[i];
            var h = heights[i];
            if (kind == :card) {
                card = cardAt(dc, rows, ys, heights, i);
                Theme.card(dc, card[0], card[2], card[1], card[3] - card[2]);
            } else if (kind == :end) {
                card = null;
            } else if (kind == :big || kind == :small) {
                var font = kind == :big ? tier[0] : tier[2];
                textAt(dc, y, font, fit(dc, row[1], font, rowRoom(dc, ys, heights, i, card)), row[2]);
            } else if (kind == :pill) {
                pill(dc, y + h / 2, row[1], row[2], tier[2]);
            } else if (kind == :value) {
                var bw = boxW(dc, row[1], null, tier[1], tier[2]);
                box(dc, (dc.getWidth() - bw) / 2, y, bw, h, row[1], null, row[2], true, tier[1], tier[2]);
            } else if (kind == :icon) {
                icon(dc, y + h / 2);
            } else if (kind == :badge) {
                dc.setColor(RED, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dc.getWidth() / 2, y + h / 2, h / 2);
                center(dc, y + h / 2, tier[2], "!", BG);
            }
        }
    }

    function bannerText() {
        var c = getController();
        if (c.notice() != null) {
            return c.notice();
        }
        var queued = Store.queue().size();
        if (c.sync().isOffline() && queued > 0) {
            return "Offline · " + queued + " queued";
        }
        return null;
    }

    // The round screen is narrow near the edges; at 15% or 89% height a line has about 270 px.
    function bannerAt(dc, fraction) {
        var text = bannerText();
        if (text != null) {
            center(dc, dc.getHeight() * fraction, Graphics.FONT_XTINY, text, GREY);
        }
    }
}
