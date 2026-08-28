import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: pagerViewRoot

    property int currentIndex: 0
    property int numberOfDesktops: 1
    property var desktopsWithWindows: ({})
    property var desktopNames: []
    property var desktopIds: []
    
    // Scale modifier: 0 = compact, 1 = full padding
    property int scaleModifier: 0 
    
    readonly property real smallSpacing: Kirigami.Units.smallSpacing
    readonly property real gridUnit: Kirigami.Units.gridUnit
    
    readonly property int indicatorStyle: Plasmoid.configuration.indicatorStyle
    readonly property bool isPills: indicatorStyle === 0
    readonly property bool isBox: indicatorStyle > 0
    readonly property bool isLabels: indicatorStyle === 2
    readonly property bool useSysColors: Plasmoid.configuration.useSystemColors
    readonly property color indicatorColor: useSysColors ? Kirigami.Theme.highlightColor : Plasmoid.configuration.windowIndicatorColor

    // Computed properties for Pills
    readonly property real pillDotSize: Math.round(smallSpacing * Math.max(1, Plasmoid.configuration.pillsDotSize + scaleModifier))
    readonly property real pillLineSize: Math.round(smallSpacing * Math.max(2, Plasmoid.configuration.pillsLineLength + (scaleModifier * 2)))
    readonly property real pillGap: Math.round(smallSpacing * Math.max(0, Plasmoid.configuration.pillsGap + scaleModifier))
    readonly property real pillMargin: smallSpacing * Math.max(0, Plasmoid.configuration.pillsMargin + scaleModifier)

    // Computed properties for Boxes/Labels
    readonly property real boxUnit: isLabels ? smallSpacing : gridUnit
    readonly property real boxWidth: isBox ? Math.round(boxUnit * Math.max(3, (isLabels ? Plasmoid.configuration.lblBoxWidth : Plasmoid.configuration.numBoxWidth) + (scaleModifier * 2)) / 10) : 0
    readonly property real boxHeight: isBox ? Math.round(boxUnit * Math.max(2, (isLabels ? Plasmoid.configuration.lblBoxHeight : Plasmoid.configuration.numBoxHeight) + scaleModifier) / 10) : 0
    readonly property real boxGap: isBox ? Math.round(smallSpacing * Math.max(0, (isLabels ? Plasmoid.configuration.lblGap : Plasmoid.configuration.numGap) + scaleModifier)) : 0
    readonly property real boxMargin: isBox ? smallSpacing * Math.max(0, (isLabels ? Plasmoid.configuration.lblMargin : Plasmoid.configuration.numMargin) + scaleModifier) : 0

    readonly property color activeTextColor: useSysColors ? Kirigami.Theme.highlightedTextColor : (isLabels ? Plasmoid.configuration.lblActiveColor : Plasmoid.configuration.numActiveColor)
    readonly property color inactiveTextColor: useSysColors ? Kirigami.Theme.textColor : (isLabels ? Plasmoid.configuration.lblInactiveColor : Plasmoid.configuration.numInactiveColor)

    readonly property real gap: isPills ? pillGap : boxGap
    readonly property real margin: isPills ? pillMargin : boxMargin

    readonly property real exactWidth: isPills 
        ? pillLineSize + (numberOfDesktops - 1) * pillDotSize + (numberOfDesktops - 1) * gap + margin * 2 
        : (isLabels ? row.implicitWidth + margin * 2 : numberOfDesktops * boxWidth + (numberOfDesktops - 1) * gap + margin * 2)

    implicitWidth: exactWidth
    Layout.minimumWidth: exactWidth
    Layout.preferredWidth: exactWidth
    
    implicitHeight: isPills 
        ? (scaleModifier === 0 ? Math.round(gridUnit * 1.5) : gridUnit * 2.5) 
        : (isLabels ? row.implicitHeight + margin * 2 : boxHeight + margin * 2)

    visible: numberOfDesktops > 1

    signal requestSwitchDesktop(int index)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        enabled: Plasmoid.configuration.enableScroll
        onWheel: function (wheel) {
            if (wheel.angleDelta.y > 0) {
                var nextIdx = currentIndex - 1;
                if (nextIdx < 0) {
                    if (Plasmoid.configuration.scrollCyclic)
                        nextIdx = numberOfDesktops - 1;
                    else
                        return;
                }
                requestSwitchDesktop(nextIdx);
            } else if (wheel.angleDelta.y < 0) {
                var nextIdx = currentIndex + 1;
                if (nextIdx >= numberOfDesktops) {
                    if (Plasmoid.configuration.scrollCyclic)
                        nextIdx = 0;
                    else
                        return;
                }
                requestSwitchDesktop(nextIdx);
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: pagerViewRoot.gap

        Repeater {
            model: pagerViewRoot.numberOfDesktops

            delegate: DesktopDelegate {
                isCurrent: model.index === pagerViewRoot.currentIndex
                hasWindows: pagerViewRoot.desktopIds && model.index < pagerViewRoot.desktopIds.length && pagerViewRoot.desktopsWithWindows[pagerViewRoot.desktopIds[model.index]] === true
                desktopIndex: model.index
                desktopName: pagerViewRoot.desktopNames && model.index < pagerViewRoot.desktopNames.length ? pagerViewRoot.desktopNames[model.index] : ""
                
                isPills: pagerViewRoot.isPills
                isBox: pagerViewRoot.isBox
                isLabels: pagerViewRoot.isLabels
                useSysColors: pagerViewRoot.useSysColors
                indicatorColor: pagerViewRoot.indicatorColor
                
                pillDotSize: pagerViewRoot.pillDotSize
                pillLineSize: pagerViewRoot.pillLineSize
                boxWidth: pagerViewRoot.boxWidth
                boxHeight: pagerViewRoot.boxHeight
                gridUnit: pagerViewRoot.gridUnit
                
                activeTextColor: pagerViewRoot.activeTextColor
                inactiveTextColor: pagerViewRoot.inactiveTextColor
                
                animationDuration: scaleModifier === 0 ? 160 : 200

                onClicked: requestSwitchDesktop(model.index)
            }
        }
    }
}
