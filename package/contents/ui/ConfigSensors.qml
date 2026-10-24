import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support
import "../code/sensors.js" as Sensors

KCM.SimpleKCM {
    id: page

    property var cfg_selectedSensors: []
    property var cfg_selectedSensorsDefault: []
    property string cfg_sensorLabels: "{}"
    property string cfg_sensorLabelsDefault: "{}"

    property var discovered: []
    readonly property var aliasMap: {
        try { return JSON.parse(cfg_sensorLabels) } catch (e) { return {} }
    }

    function isSelected(id) { return cfg_selectedSensors.indexOf(id) >= 0 }

    function setSelected(id, on) {
        var l = cfg_selectedSensors.slice();
        var i = l.indexOf(id);
        if (on && i < 0) l.push(id);
        if (!on && i >= 0) l.splice(i, 1);
        cfg_selectedSensors = l;
    }

    function move(id, dir) {
        var l = cfg_selectedSensors.slice();
        var i = l.indexOf(id), j = i + dir;
        if (i < 0 || j < 0 || j >= l.length) return;
        var t = l[i]; l[i] = l[j]; l[j] = t;
        cfg_selectedSensors = l;
    }

    function setAlias(id, text) {
        var m = JSON.parse(JSON.stringify(aliasMap));
        if (text.length) m[id] = text; else delete m[id];
        cfg_sensorLabels = JSON.stringify(m);
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: [Sensors.command(true)]
        interval: 3000
        onNewData: (source, data) => page.discovered = Sensors.parse(data["stdout"] || "")
    }

    ColumnLayout {
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            text: i18n("Tick the sensors to show. Selected sensors can be reordered and renamed. Many Super-I/O temp channels are unused and read 0 or constant values.")
        }
        Kirigami.PlaceholderMessage {
            Layout.fillWidth: true
            visible: page.discovered.length === 0
            text: i18n("Scanning sensors…")
        }

        Repeater {
            model: page.discovered
            delegate: RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                QQC.CheckBox {
                    checked: page.isSelected(row.modelData.id)
                    onToggled: page.setSelected(row.modelData.id, checked)
                    text: row.modelData.label
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 11
                }
                QQC.Label {
                    text: row.modelData.raw || ""
                    font: Kirigami.Theme.smallFont
                    opacity: 0.55
                    elide: Text.ElideRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                }
                QQC.Label {
                    text: Sensors.format(row.modelData.kind, row.modelData.value, false) + " " + Sensors.unit(row.modelData.kind, false)
                    opacity: 0.7
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                }
                QQC.TextField {
                    Layout.fillWidth: true
                    enabled: page.isSelected(row.modelData.id)
                    placeholderText: i18n("Custom name")
                    text: page.aliasMap[row.modelData.id] || ""
                    onEditingFinished: page.setAlias(row.modelData.id, text)
                }
                QQC.ToolButton {
                    icon.name: "go-up"
                    enabled: page.isSelected(row.modelData.id)
                    onClicked: page.move(row.modelData.id, -1)
                }
                QQC.ToolButton {
                    icon.name: "go-down"
                    enabled: page.isSelected(row.modelData.id)
                    onClicked: page.move(row.modelData.id, 1)
                }
            }
        }
    }
}
