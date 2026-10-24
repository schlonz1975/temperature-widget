import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../code/sensors.js" as Sensors

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property var selected: cfg.selectedSensors
    readonly property var aliases: {
        try { return JSON.parse(cfg.sensorLabels) } catch (e) { return {} }
    }
    readonly property real sizeScale: [0.85, 1.15, 1.6][Math.max(0, Math.min(2, cfg.sizePreset))]
    readonly property bool wantNvidia: selected.some(function (id) { return id.indexOf("n:") === 0 })
    readonly property string pollCommand: Sensors.command(wantNvidia)

    property var readings: ({})
    property var hist: ({})
    property int histRev: 0

    readonly property var pal: palette()

    // Entries must be real color objects: consumers read .r/.g/.b
    function palette() {
        var p = rawPalette();
        for (var k in p) p[k] = Qt.color(p[k]);
        return p;
    }

    function rawPalette() {
        var c = cfg;
        switch (c.colorTheme) {
        case 1: return { bg: "#2e3440", text: "#eceff4", cool: "#a3be8c", warm: "#ebcb8b", hot: "#bf616a", accent: "#88c0d0" };
        case 2: return { bg: "#282a36", text: "#f8f8f2", cool: "#50fa7b", warm: "#f1fa8c", hot: "#ff5555", accent: "#bd93f9" };
        case 3: return { bg: "#282828", text: "#ebdbb2", cool: "#b8bb26", warm: "#fabd2f", hot: "#fb4934", accent: "#83a598" };
        case 4: return { bg: "#0d0221", text: "#e8f4ff", cool: "#05ffa1", warm: "#fffb96", hot: "#ff2a6d", accent: "#01c8ee" };
        case 5: return { bg: "#1c1c1c", text: "#f0f0f0", cool: "#cfcfcf", warm: "#9e9e9e", hot: "#ffffff", accent: "#e0e0e0" };
        case 6: return { bg: c.customBg, text: c.customText, cool: c.customCool, warm: c.customWarm, hot: c.customHot, accent: c.customAccent };
        default: return {
            bg: Kirigami.Theme.backgroundColor, text: Kirigami.Theme.textColor,
            cool: Kirigami.Theme.positiveTextColor, warm: Kirigami.Theme.neutralTextColor,
            hot: Kirigami.Theme.negativeTextColor, accent: Kirigami.Theme.highlightColor
        };
        }
    }

    function labelFor(id) {
        var r = readings[id];
        return aliases[id] || (r ? r.label : Sensors.defaultLabel(id));
    }

    function rebuild() {
        sensorModel.clear();
        for (var i = 0; i < selected.length; ++i) {
            var id = selected[i];
            sensorModel.append({ sid: id, label: labelFor(id), value: 0, ok: false, kind: Sensors.kindOf(id) });
        }
        refresh();
    }

    function refresh() {
        for (var i = 0; i < sensorModel.count; ++i) {
            var id = sensorModel.get(i).sid;
            var r = readings[id];
            sensorModel.setProperty(i, "label", labelFor(id));
            sensorModel.setProperty(i, "ok", !!r);
            if (r) sensorModel.setProperty(i, "value", r.value);
        }
    }

    function handleOutput(out) {
        var list = Sensors.parse(out);
        var map = {};
        for (var i = 0; i < list.length; ++i) map[list[i].id] = list[i];
        readings = map;
        var maxLen = Math.max(5, cfg.historyLength);
        var h = hist;
        for (var j = 0; j < selected.length; ++j) {
            var r = map[selected[j]];
            if (!r) continue;
            var arr = (h[selected[j]] || []).concat([r.value]);  // new array so bindings notify
            if (arr.length > maxLen) arr = arr.slice(arr.length - maxLen);
            h[selected[j]] = arr;
        }
        hist = h;
        histRev++;
        refresh();
    }

    ListModel { id: sensorModel }

    Connections {
        target: Plasmoid.configuration
        function onSelectedSensorsChanged() { root.rebuild() }
        function onSensorLabelsChanged() { root.refresh() }
    }
    Component.onCompleted: rebuild()

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            root.handleOutput(data["stdout"] || "");
        }
    }

    Timer {
        interval: Math.max(1, root.cfg.updateInterval) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: exec.connectSource(root.pollCommand)
    }

    Plasmoid.backgroundHints: cfg.showFrame ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground
    toolTipMainText: i18n("Hardware sensors")
    toolTipSubText: {
        var s = [];
        for (var i = 0; i < sensorModel.count; ++i) {
            var m = sensorModel.get(i);
            s.push(m.label + ": " + Sensors.format(m.kind, m.ok ? m.value : NaN, cfg.fahrenheit) + " " + Sensors.unit(m.kind, cfg.fahrenheit));
        }
        return s.join("\n");
    }

    compactRepresentation: MouseArea {
        id: compact
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        Layout.minimumWidth: flow.implicitWidth
        Layout.minimumHeight: flow.implicitHeight
        onClicked: root.expanded = !root.expanded

        GridLayout {
            id: flow
            anchors.centerIn: parent
            columns: compact.vertical ? 1 : Math.max(1, sensorModel.count)
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            Repeater {
                model: sensorModel
                Text {
                    required property var model
                    readonly property real v: model.ok ? model.value : NaN
                    text: Sensors.format(model.kind, v, root.cfg.fahrenheit) + Sensors.unit(model.kind, root.cfg.fahrenheit)
                    color: Sensors.severityColor(model.kind, v, root.pal, root.cfg.warnTemp, root.cfg.critTemp)
                    font: Kirigami.Theme.defaultFont
                }
            }
        }
    }

    fullRepresentation: Item {
        id: full
        readonly property real gu: Kirigami.Units.gridUnit
        Layout.minimumWidth: gu * 7
        Layout.minimumHeight: gu * 4
        implicitWidth: grid.implicitWidth
        implicitHeight: grid.implicitHeight

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - full.gu * 2
            visible: sensorModel.count === 0
            text: i18n("No sensors selected")
            explanation: i18n("Right-click, Configure, Sensors.")
        }

        GridLayout {
            id: grid
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing
            columns: Math.max(1, Math.min(root.cfg.columns, Math.max(1, sensorModel.count)))
            columnSpacing: Kirigami.Units.smallSpacing * root.sizeScale * 1.5
            rowSpacing: columnSpacing

            Repeater {
                model: sensorModel
                SensorCard {
                    required property var model
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    label: model.label
                    kind: model.kind
                    value: model.ok ? model.value : NaN
                    hist: { root.histRev; return root.hist[model.sid] || [] }
                    pal: root.pal
                    mode: root.cfg.displayMode
                    style: root.cfg.graphicStyle
                    sz: root.sizeScale
                    fahrenheit: root.cfg.fahrenheit
                    warn: root.cfg.warnTemp
                    crit: root.cfg.critTemp
                    fanMax: root.cfg.fanMax
                    cardOpacity: root.cfg.cardOpacity
                    historyLength: root.cfg.historyLength
                }
            }
        }
    }
}
