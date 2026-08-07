import QtQuick
import QtQuick.Layouts
import org.kde.taskmanager as TaskManager
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    toolTipMainText: ""
    toolTipSubText: ""

    TaskManager.VirtualDesktopInfo {
        id: deskInfo
    }

    property int currentIndex: 0
    property int numberOfDesktops: 1
    property var desktopsWithWindows: ({})
    property int windowMapVersion: 0

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortDisabled
        groupMode: TaskManager.TasksModel.GroupDisabled
        onCountChanged: Qt.callLater(root.updateWindowMap)
        onDataChanged: Qt.callLater(root.updateWindowMap)
    }

    Instantiator {
        id: windowInstantiator
        model: tasksModel

        onObjectAdded: Qt.callLater(root.updateWindowMap)
        onObjectRemoved: Qt.callLater(root.updateWindowMap)

        delegate: QtObject {
            property var taskVirtualDesktops: model.VirtualDesktops
            onTaskVirtualDesktopsChanged: Qt.callLater(root.updateWindowMap)
        }
    }

    Connections {
        target: deskInfo
        function onCurrentDesktopChanged() {
            refresh();
        }
        function onNumberOfDesktopsChanged() {
            refresh();
        }
        function onDesktopIdsChanged() {
            refresh();
        }
    }

    Component.onCompleted: {
        refresh();
        updateWindowMap();
    }

    function refresh() {
        var current = deskInfo.currentDesktop;
        if (typeof current === "string")
            currentIndex = Math.max(0, deskInfo.desktopIds.indexOf(current));
        else
            currentIndex = Math.max(0, (Number(current) || 1) - 1);
        numberOfDesktops = deskInfo.numberOfDesktops;
    }

    function switchTo(index) {
        if (index === currentIndex || index >= numberOfDesktops)
            return;
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/KWin",
            iface: "org.kde.KWin",
            member: "setCurrentDesktop",
            arguments: [new DBus.int32(index + 1)]
        });
    }

    function updateWindowMap() {
        var result = {};
        for (var i = 0; i < windowInstantiator.count; i++) {
            var obj = windowInstantiator.objectAt(i);
            if (!obj)
                continue;
            var vds = obj.taskVirtualDesktops;
            if (vds && vds.length > 0) {
                for (var j = 0; j < vds.length; j++) {
                    result[vds[j]] = true;
                }
            }
        }
        desktopsWithWindows = result;
        windowMapVersion++;
    }

    function desktopHasWindows(idx) {
        windowMapVersion;
        var did = deskInfo.desktopIds[idx];
        return did !== undefined && desktopsWithWindows[did] === true;
    }

    compactRepresentation: Item {
        id: rep

        readonly property real s: Kirigami.Units.smallSpacing
        readonly property real gu: Kirigami.Units.gridUnit
        readonly property int st: plasmoid.configuration.indicatorStyle
        readonly property bool isPills: st === 0
        readonly property bool isBox: st > 0
        readonly property bool isLabels: st === 2
        readonly property bool useSys: plasmoid.configuration.useSystemColors
        readonly property color indicatorColor: useSys ? Kirigami.Theme.highlightColor : plasmoid.configuration.windowIndicatorColor

        readonly property real pillDot: Math.round(s * Math.max(1, plasmoid.configuration.pillsDotSize))
        readonly property real pillLine: Math.round(s * Math.max(2, plasmoid.configuration.pillsLineLength))
        readonly property real pillGap: Math.round(s * Math.max(0, plasmoid.configuration.pillsGap))
        readonly property real pillMargin: s * Math.max(0, plasmoid.configuration.pillsMargin)

        readonly property real boxUnit: isLabels ? s : gu
        readonly property real boxW: isBox ? Math.round(boxUnit * Math.max(3, st === 1 ? plasmoid.configuration.numBoxWidth : plasmoid.configuration.lblBoxWidth) / 10) : 0
        readonly property real boxH: isBox ? Math.round(boxUnit * Math.max(2, st === 1 ? plasmoid.configuration.numBoxHeight : plasmoid.configuration.lblBoxHeight) / 10) : 0
        readonly property real boxGap: isBox ? Math.round(s * Math.max(0, st === 1 ? plasmoid.configuration.numGap : plasmoid.configuration.lblGap)) : 0
        readonly property real boxMargin: isBox ? s * Math.max(0, st === 1 ? plasmoid.configuration.numMargin : plasmoid.configuration.lblMargin) : 0

        readonly property color repActiveTextColor: useSys ? Kirigami.Theme.highlightedTextColor : (st === 1 ? plasmoid.configuration.numActiveColor : plasmoid.configuration.lblActiveColor)
        readonly property color repInactiveTextColor: useSys ? Kirigami.Theme.textColor : (st === 1 ? plasmoid.configuration.numInactiveColor : plasmoid.configuration.lblInactiveColor)

        readonly property real gap: isPills ? pillGap : boxGap
        readonly property real margin: isPills ? pillMargin : boxMargin

        readonly property real exactWidth: isPills ? pillLine + (root.numberOfDesktops - 1) * pillDot + (root.numberOfDesktops - 1) * gap + margin * 2 : isLabels ? row.implicitWidth + margin * 2 : root.numberOfDesktops * boxW + (root.numberOfDesktops - 1) * gap + margin * 2

        implicitWidth: exactWidth
        Layout.minimumWidth: exactWidth
        Layout.preferredWidth: exactWidth

        implicitHeight: isPills ? Math.round(gu * 1.5) : isLabels ? row.implicitHeight + margin * 2 : boxH + margin * 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: plasmoid.configuration.enableScroll
            onWheel: function (wheel) {
                if (wheel.angleDelta.y > 0) {
                    var nextIdx = root.currentIndex - 1;
                    if (nextIdx < 0) {
                        if (plasmoid.configuration.scrollCyclic)
                            nextIdx = root.numberOfDesktops - 1;
                        else
                            return;
                    }
                    root.switchTo(nextIdx);
                } else if (wheel.angleDelta.y < 0) {
                    var nextIdx = root.currentIndex + 1;
                    if (nextIdx >= root.numberOfDesktops) {
                        if (plasmoid.configuration.scrollCyclic)
                            nextIdx = 0;
                        else
                            return;
                    }
                    root.switchTo(nextIdx);
                }
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: rep.gap

            Repeater {
                model: root.numberOfDesktops

                delegate: Item {
                    readonly property bool isCurrent: model.index === root.currentIndex
                    readonly property bool hasWindows: root.desktopHasWindows(model.index)

                    width: rep.isPills ? (isCurrent ? rep.pillLine : rep.pillDot) : rep.isLabels ? Math.max(labelText.implicitWidth + rep.boxW * 2, rep.boxW) : rep.boxW
                    height: rep.isPills ? rep.pillDot : rep.isLabels ? Math.max(labelText.implicitHeight + rep.boxH * 2, rep.boxH) : rep.boxH

                    Behavior on width {
                        enabled: rep.isPills
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        visible: rep.isPills
                        anchors.centerIn: parent
                        width: parent.width
                        height: isCurrent ? rep.pillDot * 0.6 : rep.pillDot
                        radius: height / 2
                        color: isCurrent ? (rep.useSys ? Kirigami.Theme.highlightColor : plasmoid.configuration.pillsActiveColor) : (rep.useSys ? Kirigami.Theme.textColor : plasmoid.configuration.pillsInactiveColor)
                        opacity: (isCurrent ? plasmoid.configuration.pillsActiveOpacity : plasmoid.configuration.pillsInactiveOpacity) / 100

                        border.width: (!isCurrent && hasWindows && plasmoid.configuration.showWindowIndicator) ? 3 : 0
                        border.color: rep.indicatorColor

                        Behavior on height {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        visible: rep.isBox
                        anchors.fill: parent
                        radius: Math.round(parent.height * (rep.isLabels ? plasmoid.configuration.lblBoxRadius : plasmoid.configuration.numBoxRadius) / 100)
                        color: isCurrent ? (rep.useSys ? Kirigami.Theme.highlightColor : (rep.isLabels ? plasmoid.configuration.lblActiveBgColor : (plasmoid.configuration.numShowBg ? plasmoid.configuration.numActiveBgColor : "transparent"))) : (rep.useSys ? "transparent" : (rep.isLabels ? plasmoid.configuration.lblInactiveBgColor : (plasmoid.configuration.numShowBg ? plasmoid.configuration.numInactiveBgColor : "transparent")))
                        opacity: (isCurrent ? (rep.isLabels ? plasmoid.configuration.lblActiveOpacity : plasmoid.configuration.numActiveOpacity) : (rep.isLabels ? plasmoid.configuration.lblInactiveOpacity : plasmoid.configuration.numInactiveOpacity)) / 100

                        border {
                            width: (rep.isLabels ? plasmoid.configuration.lblShowBorder : plasmoid.configuration.numShowBorder) ? (rep.isLabels ? plasmoid.configuration.lblBorderThickness : plasmoid.configuration.numBorderThickness) : 0
                            color: (rep.isLabels ? plasmoid.configuration.lblShowBorder : plasmoid.configuration.numShowBorder) ? (rep.useSys ? Kirigami.Theme.textColor : (rep.isLabels ? plasmoid.configuration.lblBorderColor : plasmoid.configuration.numBorderColor)) : "transparent"
                        }

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: rep.isLabels ? (deskInfo.desktopNames && index < deskInfo.desktopNames.length ? deskInfo.desktopNames[index] : (index + 1)) : (index + 1)
                            color: isCurrent ? rep.repActiveTextColor : rep.repInactiveTextColor
                            opacity: 1.0
                            font {
                                pixelSize: {
                                    var fs = rep.isLabels ? plasmoid.configuration.lblFontSize : plasmoid.configuration.numFontSize;
                                    if (fs > 0)
                                        return fs;
                                    return rep.isLabels ? Math.round(rep.gu * 0.65) : Math.round(rep.boxH * 0.55);
                                }
                                bold: rep.isLabels ? plasmoid.configuration.lblFontBold : plasmoid.configuration.numFontBold
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            fontSizeMode: rep.isLabels ? Text.FixedSize : Text.HorizontalFit
                            minimumPixelSize: Math.round(rep.boxH * 0.3)
                        }
                    }

                    Rectangle {
                        visible: rep.isBox && !isCurrent && hasWindows && plasmoid.configuration.showWindowIndicator
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.5
                        height: 4
                        radius: 1
                        color: rep.indicatorColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: rep.isPills ? -Kirigami.Units.smallSpacing : 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchTo(model.index)
                    }
                }
            }
        }
    }

    fullRepresentation: Item {
        id: full

        readonly property real s: Kirigami.Units.smallSpacing
        readonly property real gu: Kirigami.Units.gridUnit
        readonly property int st: plasmoid.configuration.indicatorStyle
        readonly property bool isPills: st === 0
        readonly property bool isBox: st > 0
        readonly property bool isLabels: st === 2
        readonly property bool useSys: plasmoid.configuration.useSystemColors
        readonly property color indicatorColor: useSys ? Kirigami.Theme.highlightColor : plasmoid.configuration.windowIndicatorColor

        readonly property real pillDot: Math.round(s * Math.max(1, plasmoid.configuration.pillsDotSize + 1))
        readonly property real pillLine: Math.round(s * Math.max(2, plasmoid.configuration.pillsLineLength + 2))
        readonly property real pillGap: Math.round(s * Math.max(0, plasmoid.configuration.pillsGap + 1))
        readonly property real pillMargin: s * Math.max(0, plasmoid.configuration.pillsMargin + 1)

        readonly property real boxUnit: full.isLabels ? s : gu
        readonly property real boxW: isBox ? Math.round(boxUnit * Math.max(3, (st === 1 ? plasmoid.configuration.numBoxWidth : plasmoid.configuration.lblBoxWidth) + 2) / 10) : 0
        readonly property real boxH: isBox ? Math.round(boxUnit * Math.max(2, (st === 1 ? plasmoid.configuration.numBoxHeight : plasmoid.configuration.lblBoxHeight) + 1) / 10) : 0
        readonly property real boxGap: isBox ? Math.round(s * Math.max(0, (st === 1 ? plasmoid.configuration.numGap : plasmoid.configuration.lblGap) + 1)) : 0
        readonly property real boxMargin: isBox ? s * Math.max(0, (st === 1 ? plasmoid.configuration.numMargin : plasmoid.configuration.lblMargin) + 1) : 0

        readonly property color fullActiveTextColor: useSys ? Kirigami.Theme.highlightedTextColor : (st === 1 ? plasmoid.configuration.numActiveColor : plasmoid.configuration.lblActiveColor)
        readonly property color fullInactiveTextColor: useSys ? Kirigami.Theme.textColor : (st === 1 ? plasmoid.configuration.numInactiveColor : plasmoid.configuration.lblInactiveColor)

        readonly property real gap: isPills ? pillGap : boxGap
        readonly property real margin: isPills ? pillMargin : boxMargin

        readonly property real exactWidth: isPills ? pillLine + (root.numberOfDesktops - 1) * pillDot + (root.numberOfDesktops - 1) * gap + margin * 2 : full.isLabels ? row.implicitWidth + margin * 2 : root.numberOfDesktops * boxW + (root.numberOfDesktops - 1) * gap + margin * 2

        implicitWidth: exactWidth
        implicitHeight: isPills ? Kirigami.Units.gridUnit * 2.5 : full.isLabels ? row.implicitHeight + margin * 2 : boxH + margin * 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: plasmoid.configuration.enableScroll
            onWheel: function (wheel) {
                if (wheel.angleDelta.y > 0) {
                    var nextIdx = root.currentIndex - 1;
                    if (nextIdx < 0) {
                        if (plasmoid.configuration.scrollCyclic)
                            nextIdx = root.numberOfDesktops - 1;
                        else
                            return;
                    }
                    root.switchTo(nextIdx);
                } else if (wheel.angleDelta.y < 0) {
                    var nextIdx = root.currentIndex + 1;
                    if (nextIdx >= root.numberOfDesktops) {
                        if (plasmoid.configuration.scrollCyclic)
                            nextIdx = 0;
                        else
                            return;
                    }
                    root.switchTo(nextIdx);
                }
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: parent.gap

            Repeater {
                model: root.numberOfDesktops

                delegate: Item {
                    readonly property bool isCurrent: model.index === root.currentIndex
                    readonly property bool hasWindows: root.desktopHasWindows(model.index)

                    width: full.isPills ? (isCurrent ? full.pillLine : full.pillDot) : full.isLabels ? Math.max(labelText.implicitWidth + full.boxW * 2, full.boxW) : full.boxW
                    height: full.isPills ? full.pillDot : full.isLabels ? Math.max(labelText.implicitHeight + full.boxH * 2, full.boxH) : full.boxH

                    Behavior on width {
                        enabled: full.isPills
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        visible: full.isPills
                        anchors.centerIn: parent
                        width: parent.width
                        height: isCurrent ? full.pillDot * 0.6 : full.pillDot
                        radius: height / 2
                        color: isCurrent ? (full.useSys ? Kirigami.Theme.highlightColor : plasmoid.configuration.pillsActiveColor) : (full.useSys ? Kirigami.Theme.textColor : plasmoid.configuration.pillsInactiveColor)
                        opacity: (isCurrent ? plasmoid.configuration.pillsActiveOpacity : plasmoid.configuration.pillsInactiveOpacity) / 100

                        border.width: (!isCurrent && hasWindows && plasmoid.configuration.showWindowIndicator) ? 3 : 0
                        border.color: full.indicatorColor

                        Behavior on height {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        visible: full.isBox
                        anchors.fill: parent
                        radius: Math.round(parent.height * (full.isLabels ? plasmoid.configuration.lblBoxRadius : plasmoid.configuration.numBoxRadius) / 100)
                        color: isCurrent ? (full.useSys ? Kirigami.Theme.highlightColor : (full.isLabels ? plasmoid.configuration.lblActiveBgColor : (plasmoid.configuration.numShowBg ? plasmoid.configuration.numActiveBgColor : "transparent"))) : (full.useSys ? "transparent" : (full.isLabels ? plasmoid.configuration.lblInactiveBgColor : (plasmoid.configuration.numShowBg ? plasmoid.configuration.numInactiveBgColor : "transparent")))
                        opacity: (isCurrent ? (full.isLabels ? plasmoid.configuration.lblActiveOpacity : plasmoid.configuration.numActiveOpacity) : (full.isLabels ? plasmoid.configuration.lblInactiveOpacity : plasmoid.configuration.numInactiveOpacity)) / 100
                        border {
                            width: (full.isLabels ? plasmoid.configuration.lblShowBorder : plasmoid.configuration.numShowBorder) ? (full.isLabels ? plasmoid.configuration.lblBorderThickness : plasmoid.configuration.numBorderThickness) : 0
                            color: (full.isLabels ? plasmoid.configuration.lblShowBorder : plasmoid.configuration.numShowBorder) ? (full.useSys ? Kirigami.Theme.textColor : (full.isLabels ? plasmoid.configuration.lblBorderColor : plasmoid.configuration.numBorderColor)) : "transparent"
                        }

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: full.isLabels ? (deskInfo.desktopNames && index < deskInfo.desktopNames.length ? deskInfo.desktopNames[index] : (index + 1)) : (index + 1)
                            color: isCurrent ? full.fullActiveTextColor : full.fullInactiveTextColor
                            opacity: 1.0
                            font {
                                pixelSize: {
                                    var fs = full.isLabels ? plasmoid.configuration.lblFontSize : plasmoid.configuration.numFontSize;
                                    if (fs > 0)
                                        return fs;
                                    return full.isLabels ? Math.round(full.gu * 0.65) : Math.round(full.boxH * 0.5);
                                }
                                bold: full.isLabels ? plasmoid.configuration.lblFontBold : plasmoid.configuration.numFontBold
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            fontSizeMode: full.isLabels ? Text.FixedSize : Text.HorizontalFit
                            minimumPixelSize: Math.round(full.boxH * 0.25)
                        }
                    }

                    Rectangle {
                        visible: full.isBox && !isCurrent && hasWindows && plasmoid.configuration.showWindowIndicator
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.5
                        height: 2
                        radius: 1
                        color: full.indicatorColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchTo(model.index)
                    }
                }
            }
        }
    }
}
