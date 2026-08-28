import QtQuick
import QtQuick.Layouts
import org.kde.taskmanager as TaskManager
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    toolTipMainText: ""
    toolTipSubText: ""

    Plasmoid.status: root.numberOfDesktops > 1 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Virtual Desktop")
            icon.name: "list-add"
            onTriggered: root.addDesktop()
        },
        PlasmaCore.Action {
            id: removeDesktopAction
            text: i18n("Remove Virtual Desktop")
            icon.name: "list-remove"
            enabled: root.numberOfDesktops > 1
            onTriggered: root.removeLastDesktop()
        }
    ]

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

    function addDesktop() {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/VirtualDesktopManager",
            iface: "org.kde.KWin.VirtualDesktopManager",
            member: "createDesktop",
            arguments: [new DBus.uint32(root.numberOfDesktops), "Desktop " + (root.numberOfDesktops + 1)]
        });
    }

    function removeLastDesktop() {
        if (root.numberOfDesktops <= 1) return;
        var lastId = deskInfo.desktopIds[deskInfo.desktopIds.length - 1];
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/VirtualDesktopManager",
            iface: "org.kde.KWin.VirtualDesktopManager",
            member: "removeDesktop",
            arguments: [lastId]
        });
    }

    function updateWindowMap() {
        var result = {};
        for (var i = 0; i < windowInstantiator.count; i++) {
            var obj = windowInstantiator.objectAt(i);
            if (!obj) continue;

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

    compactRepresentation: PagerView {
        currentIndex: root.currentIndex
        numberOfDesktops: root.numberOfDesktops
        desktopsWithWindows: {
            root.windowMapVersion;
            return root.desktopsWithWindows;
        }
        desktopNames: deskInfo.desktopNames
        desktopIds: deskInfo.desktopIds
        scaleModifier: 0
        onRequestSwitchDesktop: function(idx) { root.switchTo(idx); }
    }

    fullRepresentation: PagerView {
        currentIndex: root.currentIndex
        numberOfDesktops: root.numberOfDesktops
        desktopsWithWindows: {
            root.windowMapVersion;
            return root.desktopsWithWindows;
        }
        desktopNames: deskInfo.desktopNames
        desktopIds: deskInfo.desktopIds
        scaleModifier: 1
        onRequestSwitchDesktop: function(idx) { root.switchTo(idx); }
    }
}
