import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQC

KCM.SimpleKCM {
    property alias cfg_colorTheme: themeBox.currentIndex
    property alias cfg_customBg: bgBtn.color
    property alias cfg_customText: textBtn.color
    property alias cfg_customCool: coolBtn.color
    property alias cfg_customWarm: warmBtn.color
    property alias cfg_customHot: hotBtn.color
    property alias cfg_customAccent: accentBtn.color

    property int cfg_colorThemeDefault: 0
    property color cfg_customBgDefault: "#1a1b26"
    property color cfg_customTextDefault: "#c0caf5"
    property color cfg_customCoolDefault: "#9ece6a"
    property color cfg_customWarmDefault: "#e0af68"
    property color cfg_customHotDefault: "#f7768e"
    property color cfg_customAccentDefault: "#7aa2f7"

    Kirigami.FormLayout {
        QQC.ComboBox {
            id: themeBox
            Kirigami.FormData.label: i18n("Theme:")
            model: [i18n("Follow Plasma theme"), "Nord", "Dracula", "Gruvbox", "Cyberpunk", i18n("Monochrome"), i18n("Custom")]
        }
        Item { Kirigami.FormData.isSection: true; visible: themeBox.currentIndex === 6 }
        KQC.ColorButton { id: bgBtn;     visible: themeBox.currentIndex === 6; Kirigami.FormData.label: i18n("Card background:"); showAlphaChannel: false }
        KQC.ColorButton { id: textBtn;   visible: themeBox.currentIndex === 6; Kirigami.FormData.label: i18n("Text:"); showAlphaChannel: false }
        KQC.ColorButton { id: coolBtn;   visible: themeBox.currentIndex === 6; Kirigami.FormData.label: i18n("Cool / OK:"); showAlphaChannel: false }
        KQC.ColorButton { id: warmBtn;   visible: themeBox.currentIndex === 6; Kirigami.FormData.label: i18n("Warm:"); showAlphaChannel: false }
        KQC.ColorButton { id: hotBtn;    visible: themeBox.currentIndex === 6; Kirigami.FormData.label: i18n("Hot:"); showAlphaChannel: false }
        KQC.ColorButton { id: accentBtn; visible: themeBox.currentIndex === 6; Kirigami.FormData.label: i18n("Accent (fans, load, power):"); showAlphaChannel: false }
    }
}
