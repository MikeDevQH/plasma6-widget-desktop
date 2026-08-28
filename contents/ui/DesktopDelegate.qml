import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: delegateRoot

    property bool isCurrent: false
    property bool hasWindows: false
    property int desktopIndex: 0
    property string desktopName: ""
    
    // View styling properties passed from PagerView
    property bool isPills: false
    property bool isBox: false
    property bool isLabels: false
    property bool useSysColors: true
    property color indicatorColor: "transparent"

    property real pillDotSize: 0
    property real pillLineSize: 0
    property real boxWidth: 0
    property real boxHeight: 0
    property real gridUnit: Kirigami.Units.gridUnit

    property color activeTextColor: "transparent"
    property color inactiveTextColor: "transparent"
    
    property int animationDuration: 160

    width: isPills ? (isCurrent ? pillLineSize : pillDotSize) : (isLabels ? Math.max(labelText.implicitWidth + boxWidth * 2, boxWidth) : boxWidth)
    height: isPills ? pillDotSize : (isLabels ? Math.max(labelText.implicitHeight + boxHeight * 2, boxHeight) : boxHeight)

    Behavior on width {
        enabled: isPills
        NumberAnimation {
            duration: animationDuration
            easing.type: Easing.OutCubic
        }
    }

    // Pills styling
    Rectangle {
        visible: isPills
        anchors.centerIn: parent
        width: parent.width
        height: isCurrent ? pillDotSize * 0.6 : pillDotSize
        radius: height / 2
        
        color: isCurrent 
            ? (useSysColors ? Kirigami.Theme.highlightColor : Plasmoid.configuration.pillsActiveColor) 
            : (useSysColors ? Kirigami.Theme.textColor : Plasmoid.configuration.pillsInactiveColor)
        
        opacity: (isCurrent ? Plasmoid.configuration.pillsActiveOpacity : Plasmoid.configuration.pillsInactiveOpacity) / 100

        border.width: (!isCurrent && hasWindows && Plasmoid.configuration.showWindowIndicator) ? 3 : 0
        border.color: indicatorColor

        Behavior on height {
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: animationDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // Box/Labels styling
    Rectangle {
        visible: isBox
        anchors.fill: parent
        
        property real cornerRadiusRatio: isLabels ? Plasmoid.configuration.lblBoxRadius : Plasmoid.configuration.numBoxRadius
        radius: Math.round(height * cornerRadiusRatio / 100)
        
        property string confActiveBg: isLabels ? Plasmoid.configuration.lblActiveBgColor : (Plasmoid.configuration.numShowBg ? Plasmoid.configuration.numActiveBgColor : "transparent")
        property string confInactiveBg: isLabels ? Plasmoid.configuration.lblInactiveBgColor : (Plasmoid.configuration.numShowBg ? Plasmoid.configuration.numInactiveBgColor : "transparent")
        
        color: isCurrent 
            ? (useSysColors ? Kirigami.Theme.highlightColor : confActiveBg) 
            : (useSysColors ? "transparent" : confInactiveBg)
            
        opacity: (isCurrent ? (isLabels ? Plasmoid.configuration.lblActiveOpacity : Plasmoid.configuration.numActiveOpacity) 
                            : (isLabels ? Plasmoid.configuration.lblInactiveOpacity : Plasmoid.configuration.numInactiveOpacity)) / 100

        property bool showBorder: isLabels ? Plasmoid.configuration.lblShowBorder : Plasmoid.configuration.numShowBorder
        property int borderThickness: isLabels ? Plasmoid.configuration.lblBorderThickness : Plasmoid.configuration.numBorderThickness
        property color confBorderColor: isLabels ? Plasmoid.configuration.lblBorderColor : Plasmoid.configuration.numBorderColor

        border {
            width: showBorder ? borderThickness : 0
            color: showBorder ? (useSysColors ? Kirigami.Theme.textColor : confBorderColor) : "transparent"
        }

        Text {
            id: labelText
            anchors.fill: parent
            anchors.margins: 2
            text: isLabels && desktopName !== "" ? desktopName : (desktopIndex + 1)
            color: isCurrent ? activeTextColor : inactiveTextColor
            opacity: 1.0
            
            font.pixelSize: {
                var confSize = isLabels ? Plasmoid.configuration.lblFontSize : Plasmoid.configuration.numFontSize;
                if (confSize > 0) return confSize;
                return isLabels ? Math.round(gridUnit * 0.65) : Math.round(boxHeight * 0.55);
            }
            font.bold: isLabels ? Plasmoid.configuration.lblFontBold : Plasmoid.configuration.numFontBold
            
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: isLabels ? Text.FixedSize : Text.HorizontalFit
            minimumPixelSize: Math.round(boxHeight * 0.3)
        }
    }

    // Box Window Indicator
    Rectangle {
        visible: isBox && !isCurrent && hasWindows && Plasmoid.configuration.showWindowIndicator
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.5
        height: isLabels ? 4 : (parent.height > 16 ? 4 : 2)
        radius: height / 2
        color: indicatorColor
    }
    
    signal clicked()
    MouseArea {
        anchors.fill: parent
        anchors.margins: isPills ? -Kirigami.Units.smallSpacing : 0
        cursorShape: Qt.PointingHandCursor
        onClicked: delegateRoot.clicked()
    }
}
