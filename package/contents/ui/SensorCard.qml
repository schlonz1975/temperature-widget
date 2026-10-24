import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import "../code/sensors.js" as Sensors

Item {
    id: card

    property string label
    property real value: NaN
    property string kind: "temp"
    property var hist: []
    property var pal
    property int mode: 2        // 0 numbers, 1 graphics, 2 both
    property int style: 0       // 0 gauge, 1 sparkline
    property real sz: 1
    property bool fahrenheit: false
    property real warn: 70
    property real crit: 85
    property real fanMax: 2500
    property real cardOpacity: 0.55
    property int historyLength: 60

    readonly property real gu: Kirigami.Units.gridUnit
    readonly property bool isGauge: style === 0
    readonly property bool showGfx: mode !== 0
    readonly property bool numBig: mode === 0
    readonly property bool numInGauge: mode === 2 && isGauge
    readonly property bool numInHeader: mode === 2 && !isGauge
    readonly property bool valid: !isNaN(value)
    readonly property color accent: Sensors.severityColor(kind, value, pal, warn, crit)
    readonly property string valueText: Sensors.format(kind, value, fahrenheit)
    readonly property string unitText: Sensors.unit(kind, fahrenheit)
    readonly property real frac: {
        if (!valid) return 0;
        var r = Sensors.range(kind, fanMax);
        return Math.max(0, Math.min(1, (value - r[0]) / (r[1] - r[0])));
    }

    implicitWidth: (isGauge || numBig ? gu * 6.2 : gu * 8.5) * sz
    implicitHeight: col.implicitHeight + 2 * pad
    readonly property real pad: gu * 0.6 * sz

    Rectangle {
        anchors.fill: parent
        radius: card.gu * 0.7 * card.sz
        color: Qt.rgba(pal.bg.r, pal.bg.g, pal.bg.b, card.cardOpacity)
        border.width: 1
        border.color: Qt.rgba(pal.text.r, pal.text.g, pal.text.b, 0.10)
    }

    HoverHandler { id: hover }
    QQC.ToolTip {
        visible: hover.hovered
        text: card.label + ": " + card.valueText + " " + card.unitText
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: card.gu * 0.2 * card.sz

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: card.label
                elide: Text.ElideRight
                color: Qt.rgba(pal.text.r, pal.text.g, pal.text.b, 0.7)
                font.pixelSize: card.gu * 0.62 * card.sz
                font.weight: Font.Medium
                horizontalAlignment: (card.isGauge && card.showGfx) || card.numBig ? Text.AlignHCenter : Text.AlignLeft
            }
            Text {
                visible: card.numInHeader
                text: card.valueText + " " + card.unitText
                color: card.accent
                font.pixelSize: card.gu * 0.9 * card.sz
                font.weight: Font.DemiBold
            }
        }

        // big number (numbers only)
        Row {
            visible: card.numBig
            Layout.alignment: Qt.AlignHCenter
            spacing: card.gu * 0.2 * card.sz
            Text {
                id: bigNum
                text: card.valueText
                color: card.accent
                font.pixelSize: card.gu * 2.0 * card.sz
                font.weight: Font.Light
            }
            Text {
                text: card.unitText
                anchors.baseline: bigNum.baseline
                color: Qt.rgba(pal.text.r, pal.text.g, pal.text.b, 0.65)
                font.pixelSize: card.gu * 0.7 * card.sz
            }
        }

        // gauge
        Item {
            visible: card.showGfx && card.isGauge
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: card.gu * 4.2 * card.sz
            Layout.preferredHeight: card.gu * 4.2 * card.sz

            property real shown: card.frac
            Behavior on shown { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            onShownChanged: canvas.requestPaint()

            Canvas {
                id: canvas
                anchors.fill: parent
                onWidthChanged: requestPaint()
                Connections {
                    target: card
                    function onAccentChanged() { canvas.requestPaint() }
                    function onPalChanged() { canvas.requestPaint() }
                }
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var lw = Math.max(3, card.gu * 0.38 * card.sz);
                    var r = Math.min(width, height) / 2 - lw / 2 - 1;
                    var cx = width / 2, cy = height / 2;
                    var a0 = 0.75 * Math.PI, span = 1.5 * Math.PI;
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Qt.rgba(card.pal.text.r, card.pal.text.g, card.pal.text.b, 0.14);
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, a0, a0 + span);
                    ctx.stroke();
                    if (card.valid && parent.shown > 0.005) {
                        ctx.strokeStyle = card.accent;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, a0, a0 + span * parent.shown);
                        ctx.stroke();
                    }
                }
            }

            Column {
                visible: card.numInGauge
                anchors.centerIn: parent
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.valueText
                    color: card.accent
                    font.pixelSize: card.gu * 1.25 * card.sz
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.unitText
                    color: Qt.rgba(pal.text.r, pal.text.g, pal.text.b, 0.6)
                    font.pixelSize: card.gu * 0.55 * card.sz
                }
            }
        }

        // sparkline
        Canvas {
            id: spark
            visible: card.showGfx && !card.isGauge
            Layout.fillWidth: true
            Layout.preferredHeight: card.gu * 1.9 * card.sz
            onWidthChanged: requestPaint()
            Connections {
                target: card
                function onHistChanged() { spark.requestPaint() }
                function onAccentChanged() { spark.requestPaint() }
                function onPalChanged() { spark.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var h = card.hist;
                if (!h || h.length < 2) return;
                var minSpan = { temp: 10, fan: 300, watt: 20, pct: 10 }[card.kind] || 10;
                var lo = Math.min.apply(null, h), hi = Math.max.apply(null, h);
                if (card.kind !== "temp") lo = Math.min(lo, 0);
                if (hi - lo < minSpan) { var mid = (hi + lo) / 2; lo = mid - minSpan / 2; hi = mid + minSpan / 2; }
                var maxN = Math.max(card.hist.length, 2);
                var pad = 2;
                var stepX = (width - 2 * pad) / (Math.max(card.historyLength, maxN) - 1);
                var x0 = width - pad - stepX * (h.length - 1);
                function px(i) { return x0 + i * stepX; }
                function py(v) { return height - pad - (v - lo) / (hi - lo) * (height - 2 * pad); }

                var g = ctx.createLinearGradient(0, 0, 0, height);
                g.addColorStop(0, Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.35));
                g.addColorStop(1, Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.0));
                ctx.beginPath();
                ctx.moveTo(px(0), height);
                for (var i = 0; i < h.length; ++i) ctx.lineTo(px(i), py(h[i]));
                ctx.lineTo(px(h.length - 1), height);
                ctx.closePath();
                ctx.fillStyle = g;
                ctx.fill();

                ctx.beginPath();
                for (var j = 0; j < h.length; ++j) {
                    if (j === 0) ctx.moveTo(px(j), py(h[j])); else ctx.lineTo(px(j), py(h[j]));
                }
                ctx.lineWidth = Math.max(1.5, card.sz * 1.6);
                ctx.lineJoin = "round";
                ctx.strokeStyle = card.accent;
                ctx.stroke();
            }
        }
    }
}
