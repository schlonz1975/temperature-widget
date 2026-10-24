import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_displayMode: modeBox.currentIndex
    property alias cfg_graphicStyle: styleBox.currentIndex
    property alias cfg_sizePreset: sizeBox.currentIndex
    property alias cfg_columns: columnsSpin.value
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_historyLength: historySpin.value
    property alias cfg_fahrenheit: fahrenheitCheck.checked
    property alias cfg_warnTemp: warnSpin.value
    property alias cfg_critTemp: critSpin.value
    property alias cfg_fanMax: fanMaxSpin.value
    property alias cfg_showFrame: frameCheck.checked
    property alias cfg_cardOpacity: opacitySlider.value

    property int cfg_displayModeDefault: 2
    property int cfg_graphicStyleDefault: 0
    property int cfg_sizePresetDefault: 1
    property int cfg_columnsDefault: 2
    property int cfg_updateIntervalDefault: 2
    property int cfg_historyLengthDefault: 60
    property bool cfg_fahrenheitDefault: false
    property int cfg_warnTempDefault: 70
    property int cfg_critTempDefault: 85
    property int cfg_fanMaxDefault: 2500
    property bool cfg_showFrameDefault: false
    property real cfg_cardOpacityDefault: 0.55

    Kirigami.FormLayout {
        QQC.ComboBox {
            id: modeBox
            Kirigami.FormData.label: i18n("Show:")
            model: [i18n("Numbers only"), i18n("Graphics only"), i18n("Numbers and graphics")]
        }
        QQC.ComboBox {
            id: styleBox
            Kirigami.FormData.label: i18n("Graphic style:")
            model: [i18n("Gauges"), i18n("Sparklines")]
            enabled: modeBox.currentIndex !== 0
        }
        QQC.ComboBox {
            id: sizeBox
            Kirigami.FormData.label: i18n("Size:")
            model: [i18n("Small"), i18n("Medium"), i18n("Large")]
        }
        QQC.SpinBox { id: columnsSpin; Kirigami.FormData.label: i18n("Columns:"); from: 1; to: 8 }

        Item { Kirigami.FormData.isSection: true }

        QQC.SpinBox { id: intervalSpin; Kirigami.FormData.label: i18n("Update every (s):"); from: 1; to: 60 }
        QQC.SpinBox {
            id: historySpin
            Kirigami.FormData.label: i18n("Sparkline samples:")
            from: 10; to: 600; stepSize: 10
        }
        QQC.CheckBox { id: fahrenheitCheck; Kirigami.FormData.label: i18n("Temperature:"); text: i18n("Use Fahrenheit") }

        Item { Kirigami.FormData.isSection: true }

        QQC.SpinBox { id: warnSpin; Kirigami.FormData.label: i18n("Warm from (°C):"); from: 20; to: 120 }
        QQC.SpinBox { id: critSpin; Kirigami.FormData.label: i18n("Hot from (°C):"); from: 25; to: 130 }
        QQC.SpinBox { id: fanMaxSpin; Kirigami.FormData.label: i18n("Fan gauge max (RPM):"); from: 500; to: 10000; stepSize: 100 }

        Item { Kirigami.FormData.isSection: true }

        QQC.CheckBox { id: frameCheck; Kirigami.FormData.label: i18n("Background:"); text: i18n("Show widget frame") }
        QQC.Slider {
            id: opacitySlider
            Kirigami.FormData.label: i18n("Card opacity:")
            from: 0; to: 1; stepSize: 0.05
        }
    }
}
