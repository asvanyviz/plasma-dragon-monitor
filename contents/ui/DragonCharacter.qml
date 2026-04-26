import QtQuick 2.15
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: dragon
    property int dragonState: 0  // 0=calm, 1=alert, 2=angry, 3=critical
    property real animationSpeed: 1.0
    property color baseColor: {
        switch(dragonState) {
            case 0: return plasmoid.configuration.colorCalm || "#4CAF50";
            case 1: return plasmoid.configuration.colorAlert || "#FFEB3B";
            case 2: return plasmoid.configuration.colorAngry || "#FF9800";
            case 3: return plasmoid.configuration.colorCritical || "#F44336";
            default: return "#4CAF50";
        }
    }

    // Inner content item — all animations applied here, not on the root Item
    // This preserves the root Item's position in the layout
    Item {
        id: content
        anchors.fill: parent

        // Dragon SVG or placeholder
        Image {
            id: dragonImage
            source: "../images/dragon.svg"
            sourceSize: Qt.size(parent.width, parent.height)
            anchors.fill: parent
            smooth: true
            antialiasing: true

            onStatusChanged: {
                if (status === Image.Error) {
                    placeholderRect.visible = true;
                }
            }
        }

        // Placeholder rectangle (if no SVG)
        Rectangle {
            id: placeholderRect
            anchors.fill: parent
            visible: false
            radius: width / 4
            color: dragon.baseColor
            border.color: Kirigami.Theme.textColor
            border.width: 2

            Rectangle {
                width: parent.width * 0.15
                height: width
                radius: width / 2
                color: Kirigami.Theme.textColor
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.25
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.25
            }
            Rectangle {
                width: parent.width * 0.15
                height: width
                radius: width / 2
                color: Kirigami.Theme.textColor
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.25
                anchors.right: parent.right
                anchors.rightMargin: parent.width * 0.25
            }
            Rectangle {
                width: parent.width * 0.3
                height: parent.height * 0.05
                radius: height / 2
                color: Kirigami.Theme.textColor
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.25
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Glow effect for critical state
        Rectangle {
            id: glowRect
            anchors.fill: parent
            radius: width / 4
            color: dragon.baseColor
            opacity: 0
            visible: dragonState === 3
            z: -1

            SequentialAnimation {
                loops: Animation.Infinite
                running: dragonState === 3
                NumberAnimation { target: glowRect; property: "opacity"; to: 0.5; duration: 500 / dragon.animationSpeed }
                NumberAnimation { target: glowRect; property: "opacity"; to: 0.1; duration: 500 / dragon.animationSpeed }
            }
        }

        // Breathing animation — scale the content, not the root Item
        SequentialAnimation {
            loops: Animation.Infinite
            running: true
            NumberAnimation {
                target: content
                property: "scale"
                to: dragonState <= 1 ? 1.05 : 1.12
                duration: (dragonState === 0 ? 3000 : dragonState === 1 ? 2000 : 1000) / dragon.animationSpeed
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 1.0
                duration: (dragonState === 0 ? 3000 : dragonState === 1 ? 2000 : 1000) / dragon.animationSpeed
                easing.type: Easing.InOutSine
            }
        }

        // Body sway / tail wag — rotate the content, not the root Item
        RotationAnimation {
            target: content
            property: "rotation"
            from: -6
            to: 6
            duration: (dragonState === 0 ? 2000 : dragonState === 1 ? 1200 : 600) / dragon.animationSpeed
            direction: RotationAnimation.Alternate
            loops: Animation.Infinite
            running: true
            easing.type: Easing.InOutSine
        }

        // Shake effect (angry + critical) — offset the content, not the root Item
        Timer {
            interval: 50
            running: dragonState >= 2
            repeat: true
            onTriggered: {
                var intensity = dragonState === 2 ? 2 : 4;
                content.x = (Math.random() - 0.5) * intensity;
                content.y = (Math.random() - 0.5) * intensity;
            }
            onRunningChanged: {
                if (!running) {
                    content.x = 0;
                    content.y = 0;
                }
            }
        }

        // Blink animation
        Timer {
            interval: Math.random() * 3000 + (dragonState === 0 ? 5000 : 2000)
            running: true
            repeat: true
            onTriggered: {
                blinkAnim.start();
            }
        }

        SequentialAnimation {
            id: blinkAnim
            NumberAnimation { target: dragonImage; property: "opacity"; to: 0.3; duration: 100 }
            NumberAnimation { target: dragonImage; property: "opacity"; to: 1.0; duration: 100 }
        }
    }
}
