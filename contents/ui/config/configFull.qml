import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Layouts as QtLayouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQControls
import org.kde.kcmutils as KCM
import org.kde.taskmanager
import org.kde.plasma.workspace.dbus as DBus

KCM.SimpleKCM {
    id: pageAll

    property alias cfg_indicatorStyle: indicatorStyle.currentIndex

    property alias cfg_pillsDotSize: pillsDotSize.value
    property alias cfg_pillsLineLength: pillsLineLength.value
    property alias cfg_pillsGap: pillsGap.value
    property alias cfg_pillsMargin: pillsMargin.value
    property string cfg_pillsActiveColor: "#FFFFFF"
    property string cfg_pillsInactiveColor: "#FFFFFF"
    property alias cfg_pillsActiveOpacity: pillsActiveOpacity.value
    property alias cfg_pillsInactiveOpacity: pillsInactiveOpacity.value

    property alias cfg_numBoxWidth: numBoxWidth.value
    property alias cfg_numBoxHeight: numBoxHeight.value
    property alias cfg_numFontSize: numFontSize.value
    property alias cfg_numFontBold: numFontBold.checked
    property alias cfg_numGap: numGap.value
    property alias cfg_numMargin: numMargin.value
    property string cfg_numActiveColor: "#000000"
    property string cfg_numInactiveColor: "#FFFFFF"
    property alias cfg_numShowBg: numShowBg.checked
    property string cfg_numActiveBgColor: "#FFFFFF"
    property string cfg_numInactiveBgColor: "#00000000"
    property alias cfg_numActiveOpacity: numActiveOpacity.value
    property alias cfg_numInactiveOpacity: numInactiveOpacity.value
    property alias cfg_numShowBorder: numShowBorder.checked
    property string cfg_numBorderColor: "#FFFFFF"
    property alias cfg_numBorderThickness: numBorderThickness.value
    property alias cfg_numBoxRadius: numBoxRadius.value

    property alias cfg_lblBoxWidth: lblBoxWidth.value
    property alias cfg_lblBoxHeight: lblBoxHeight.value
    property alias cfg_lblFontSize: lblFontSize.value
    property alias cfg_lblFontBold: lblFontBold.checked
    property alias cfg_lblGap: lblGap.value
    property alias cfg_lblMargin: lblMargin.value
    property string cfg_lblActiveColor: "#000000"
    property string cfg_lblInactiveColor: "#FFFFFF"
    property string cfg_lblActiveBgColor: "#FFFFFF"
    property string cfg_lblInactiveBgColor: "#00000000"
    property alias cfg_lblActiveOpacity: lblActiveOpacity.value
    property alias cfg_lblInactiveOpacity: lblInactiveOpacity.value
    property alias cfg_lblShowBorder: lblShowBorder.checked
    property string cfg_lblBorderColor: "#FFFFFF"
    property alias cfg_lblBorderThickness: lblBorderThickness.value
    property alias cfg_lblBoxRadius: lblBoxRadius.value

    readonly property int st: indicatorStyle.currentIndex

    VirtualDesktopInfo { id: deskInfo }

    function renameDesktop(idx, newName) {
        if (!newName.trim()) return
        var id = deskInfo.desktopIds[idx]
        if (!id) return
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/VirtualDesktopManager",
            iface: "org.kde.KWin.VirtualDesktopManager",
            member: "setDesktopName",
            arguments: [new DBus.string(id), new DBus.string(newName.trim())]
        })
    }

    Kirigami.FormLayout {
        // ═══════════════════════════════════════
        //  GENERAL
        // ═══════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("General")
        }

        QtControls.ComboBox {
            id: indicatorStyle
            Kirigami.FormData.label: i18n("Indicator style:")
            model: [
                i18n("Pills — dots with active pill"),
                i18n("Numbers — numbered boxes"),
                i18n("Labels — desktop names")
            ]
        }

        // ═══════════════════════════════════════
        //  PILLS
        // ═══════════════════════════════════════
        Kirigami.Separator {
            visible: pageAll.st === 0
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Pills")
        }

        QtControls.SpinBox {
            visible: pageAll.st === 0
            id: pillsDotSize; from: 1; to: 10
            Kirigami.FormData.label: i18n("Dot size:")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 0
            id: pillsLineLength; from: 1; to: 15
            Kirigami.FormData.label: i18n("Line length:")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 0
            id: pillsGap; from: 0; to: 8
            Kirigami.FormData.label: i18n("Gap:")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 0
            id: pillsMargin; from: 0; to: 6
            Kirigami.FormData.label: i18n("Margin:")
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 0
            Kirigami.FormData.label: i18n("Active color:")
            KQControls.ColorButton {
                id: pillsActiveColor
                color: cfg_pillsActiveColor
                onColorChanged: cfg_pillsActiveColor = color.toString()
                showAlphaChannel: false
            }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 0
            Kirigami.FormData.label: i18n("Inactive color:")
            KQControls.ColorButton {
                id: pillsInactiveColor
                color: cfg_pillsInactiveColor
                onColorChanged: cfg_pillsInactiveColor = color.toString()
                showAlphaChannel: false
            }
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 0
            Kirigami.FormData.label: i18n("Active opacity:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.Slider {
                id: pillsActiveOpacity; from: 10; to: 100; stepSize: 5
                QtLayouts.Layout.fillWidth: true
            }
            QtControls.Label { text: Math.round(pillsActiveOpacity.value) + "%" }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 0
            Kirigami.FormData.label: i18n("Inactive opacity:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.Slider {
                id: pillsInactiveOpacity; from: 10; to: 90; stepSize: 5
                QtLayouts.Layout.fillWidth: true
            }
            QtControls.Label { text: Math.round(pillsInactiveOpacity.value) + "%" }
        }

        // ═══════════════════════════════════════
        //  NUMBERS
        // ═══════════════════════════════════════
        Kirigami.Separator {
            visible: pageAll.st === 1
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Numbers")
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Box size:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.SpinBox { id: numBoxWidth; from: 5; to: 30 }
            QtControls.Label { text: "×" }
            QtControls.SpinBox { id: numBoxHeight; from: 4; to: 20 }
        }

        QtControls.SpinBox {
            visible: pageAll.st === 1
            id: numFontSize; from: 0; to: 40
            Kirigami.FormData.label: i18n("Font size:")
        }
        QtControls.CheckBox {
            visible: pageAll.st === 1
            id: numFontBold
            Kirigami.FormData.label: i18n("Bold:")
            text: i18n("Enabled")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 1
            id: numGap; from: 0; to: 8
            Kirigami.FormData.label: i18n("Gap:")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 1
            id: numMargin; from: 0; to: 6
            Kirigami.FormData.label: i18n("Margin:")
        }

        QtControls.CheckBox {
            visible: pageAll.st === 1
            id: numShowBg
            Kirigami.FormData.label: i18n("Show background:")
            text: i18n("Enabled")
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Active bg color:")
            KQControls.ColorButton {
                id: numActiveBgColor
                color: cfg_numActiveBgColor
                onColorChanged: cfg_numActiveBgColor = color.toString()
                showAlphaChannel: true
                enabled: numShowBg.checked
            }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Inactive bg color:")
            KQControls.ColorButton {
                id: numInactiveBgColor
                color: cfg_numInactiveBgColor
                onColorChanged: cfg_numInactiveBgColor = color.toString()
                showAlphaChannel: true
                enabled: numShowBg.checked
            }
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Active text color:")
            KQControls.ColorButton {
                id: numActiveColor
                color: cfg_numActiveColor
                onColorChanged: cfg_numActiveColor = color.toString()
                showAlphaChannel: false
            }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Inactive text color:")
            KQControls.ColorButton {
                id: numInactiveColor
                color: cfg_numInactiveColor
                onColorChanged: cfg_numInactiveColor = color.toString()
                showAlphaChannel: false
            }
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Active opacity:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.Slider {
                id: numActiveOpacity; from: 10; to: 100; stepSize: 5
                QtLayouts.Layout.fillWidth: true
            }
            QtControls.Label { text: Math.round(numActiveOpacity.value) + "%" }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Inactive opacity:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.Slider {
                id: numInactiveOpacity; from: 10; to: 90; stepSize: 5
                QtLayouts.Layout.fillWidth: true
            }
            QtControls.Label { text: Math.round(numInactiveOpacity.value) + "%" }
        }

        QtControls.CheckBox {
            visible: pageAll.st === 1
            id: numShowBorder
            Kirigami.FormData.label: i18n("Show border:")
            text: i18n("Enabled")
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 1
            Kirigami.FormData.label: i18n("Border color:")
            KQControls.ColorButton {
                id: numBorderColor
                color: cfg_numBorderColor
                onColorChanged: cfg_numBorderColor = color.toString()
                showAlphaChannel: false
                enabled: numShowBorder.checked
            }
        }
        QtControls.SpinBox {
            visible: pageAll.st === 1
            id: numBorderThickness; from: 1; to: 5
            Kirigami.FormData.label: i18n("Border thickness:")
            enabled: numShowBorder.checked
        }
        QtControls.SpinBox {
            visible: pageAll.st === 1
            id: numBoxRadius; from: 0; to: 50
            Kirigami.FormData.label: i18n("Corner radius:")
        }

        // ═══════════════════════════════════════
        //  LABELS
        // ═══════════════════════════════════════
        Kirigami.Separator {
            visible: pageAll.st === 2
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Labels")
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Padding:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.SpinBox { id: lblBoxWidth; from: 5; to: 40 }
            QtControls.Label { text: "×" }
            QtControls.SpinBox { id: lblBoxHeight; from: 2; to: 16 }
        }

        QtControls.SpinBox {
            visible: pageAll.st === 2
            id: lblFontSize; from: 0; to: 40
            Kirigami.FormData.label: i18n("Font size:")
        }
        QtControls.CheckBox {
            visible: pageAll.st === 2
            id: lblFontBold
            Kirigami.FormData.label: i18n("Bold:")
            text: i18n("Enabled")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 2
            id: lblGap; from: 0; to: 8
            Kirigami.FormData.label: i18n("Gap:")
        }
        QtControls.SpinBox {
            visible: pageAll.st === 2
            id: lblMargin; from: 0; to: 6
            Kirigami.FormData.label: i18n("Margin:")
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Active bg color:")
            KQControls.ColorButton {
                id: lblActiveBgColor
                color: cfg_lblActiveBgColor
                onColorChanged: cfg_lblActiveBgColor = color.toString()
                showAlphaChannel: true
            }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Inactive bg color:")
            KQControls.ColorButton {
                id: lblInactiveBgColor
                color: cfg_lblInactiveBgColor
                onColorChanged: cfg_lblInactiveBgColor = color.toString()
                showAlphaChannel: true
            }
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Active text color:")
            KQControls.ColorButton {
                id: lblActiveColor
                color: cfg_lblActiveColor
                onColorChanged: cfg_lblActiveColor = color.toString()
                showAlphaChannel: false
            }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Inactive text color:")
            KQControls.ColorButton {
                id: lblInactiveColor
                color: cfg_lblInactiveColor
                onColorChanged: cfg_lblInactiveColor = color.toString()
                showAlphaChannel: false
            }
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Active opacity:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.Slider {
                id: lblActiveOpacity; from: 10; to: 100; stepSize: 5
                QtLayouts.Layout.fillWidth: true
            }
            QtControls.Label { text: Math.round(lblActiveOpacity.value) + "%" }
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Inactive opacity:")
            spacing: Kirigami.Units.smallSpacing
            QtControls.Slider {
                id: lblInactiveOpacity; from: 10; to: 90; stepSize: 5
                QtLayouts.Layout.fillWidth: true
            }
            QtControls.Label { text: Math.round(lblInactiveOpacity.value) + "%" }
        }

        QtControls.CheckBox {
            visible: pageAll.st === 2
            id: lblShowBorder
            Kirigami.FormData.label: i18n("Show border:")
            text: i18n("Enabled")
        }
        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Border color:")
            KQControls.ColorButton {
                id: lblBorderColor
                color: cfg_lblBorderColor
                onColorChanged: cfg_lblBorderColor = color.toString()
                showAlphaChannel: false
                enabled: lblShowBorder.checked
            }
        }
        QtControls.SpinBox {
            visible: pageAll.st === 2
            id: lblBorderThickness; from: 1; to: 5
            Kirigami.FormData.label: i18n("Border thickness:")
            enabled: lblShowBorder.checked
        }
        QtControls.SpinBox {
            visible: pageAll.st === 2
            id: lblBoxRadius; from: 0; to: 50
            Kirigami.FormData.label: i18n("Corner radius:")
        }

        QtLayouts.RowLayout {
            visible: pageAll.st === 2
            Kirigami.FormData.label: i18n("Desktop Names")
            QtLayouts.Layout.fillWidth: true
            
            Column {
                QtLayouts.Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                Repeater {
                    model: deskInfo.numberOfDesktops
                    delegate: QtLayouts.RowLayout {
                        QtLayouts.Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        
                        QtControls.Label {
                            text: i18n("Desktop %1:", index + 1)
                            QtLayouts.Layout.minimumWidth: Kirigami.Units.gridUnit * 4
                        }
                        QtControls.TextField {
                            id: nameField
                            text: deskInfo.desktopNames && index < deskInfo.desktopNames.length
                                ? deskInfo.desktopNames[index] : ""
                            QtLayouts.Layout.fillWidth: true
                            placeholderText: i18n("Desktop %1", index + 1)
                        }
                        QtControls.Button {
                            icon.name: "dialog-ok"
                            enabled: nameField.text.trim().length > 0
                            onClicked: renameDesktop(index, nameField.text)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════
        //  RESET
        // ═══════════════════════════════════════
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Reset")
        }

        QtLayouts.RowLayout {
            QtLayouts.Layout.fillWidth: true

            QtControls.Button {
                text: i18n("Restore Defaults")
                icon.name: "edit-undo"
                onClicked: {
                    indicatorStyle.currentIndex = 0
                    pillsDotSize.value = 3
                    pillsLineLength.value = 5
                    pillsGap.value = 2
                    pillsMargin.value = 2
                    pillsActiveColor.color = "#FFFFFF"
                    pillsInactiveColor.color = "#FFFFFF"
                    pillsActiveOpacity.value = 100
                    pillsInactiveOpacity.value = 40
                    numBoxWidth.value = 16
                    numBoxHeight.value = 12
                    numFontSize.value = 0
                    numFontBold.checked = false
                    numGap.value = 2
                    numMargin.value = 2
                    numActiveColor.color = "#000000"
                    numInactiveColor.color = "#FFFFFF"
                    numShowBg.checked = true
                    numActiveBgColor.color = "#FFFFFF"
                    numInactiveBgColor.color = "#00000000"
                    numActiveOpacity.value = 100
                    numInactiveOpacity.value = 60
                    numShowBorder.checked = true
                    numBorderColor.color = "#FFFFFF"
                    numBorderThickness.value = 1
                    numBoxRadius.value = 25
                    lblBoxWidth.value = 24
                    lblBoxHeight.value = 12
                    lblFontSize.value = 0
                    lblFontBold.checked = false
                    lblGap.value = 2
                    lblMargin.value = 2
                    lblActiveColor.color = "#000000"
                    lblInactiveColor.color = "#FFFFFF"
                    lblActiveBgColor.color = "#FFFFFF"
                    lblInactiveBgColor.color = "#00000000"
                    lblActiveOpacity.value = 100
                    lblInactiveOpacity.value = 60
                    lblShowBorder.checked = true
                    lblBorderColor.color = "#FFFFFF"
                    lblBorderThickness.value = 1
                    lblBoxRadius.value = 25
                }
            }
            Item { QtLayouts.Layout.fillWidth: true }
        }
    }
}
