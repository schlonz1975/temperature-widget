import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Sensors")
        icon: "temperature-normal"
        source: "ConfigSensors.qml"
    }
    ConfigCategory {
        name: i18n("Display")
        icon: "view-visible"
        source: "ConfigDisplay.qml"
    }
    ConfigCategory {
        name: i18n("Colors")
        icon: "preferences-desktop-color"
        source: "ConfigColors.qml"
    }
}
