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

    // Dragon SVG or placeholder
    Image {
        id: dragonImage
        source: "../images/dragon.svg"
        sourceSize: Qt.size(parent.width, parent.height)
        anchors.fill: parent
        smooth: true
        antialiasing: true

        // Fallback if SVG not found
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

        // Simple dragon face
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

        SequentialAnimation {
            loops: Animation.Infinite
            running: dragonState === 3
            NumberAnimation { target: glowRect; property: "opacity"; to: 0.5; duration: 500 / dragon.animationSpeed }
            NumberAnimation { target: glowRect; property: "opacity"; to: 0.1; duration: 500 / dragon.animationSpeed }
        }
    }

    // Breathing animation
    SequentialAnimation {
        loops: Animation.Infinite
        running: true
        NumberAnimation {
            target: dragon
            property: "scale"
            to: dragonState <= 1 ? 1.05 : 1.12
            duration: (dragonState === 0 ? 3000 : dragonState === 1 ? 2000 : 1000) / dragon.animationSpeed
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: dragon
            property: "scale"
            to: 1.0
            duration: (dragonState === 0 ? 3000 : dragonState === 1 ? 2000 : 1000) / dragon.animationSpeed
            easing.type: Easing.InOutSine
        }
    }

    // Tail wag animation
    RotationAnimation {
        target: dragon
        property: "rotation"
        from: -8
        to: 8
        duration: (dragonState === 0 ? 2000 : dragonState === 1 ? 1200 : 600) / dragon.animationSpeed
        direction: RotationAnimation.Alternate
        loops: Animation.Infinite
        running: true
        easing.type: Easing.InOutSine
    }

    // Shake effect (angry + critical)
    Timer {
        interval: 50
        running: dragonState >= 2
        repeat: true
        onTriggered: {
            var intensity = dragonState === 2 ? 2 : 4;
            dragon.x = (Math.random() - 0.5) * intensity;
            dragon.y = (Math.random() - 0.5) * intensity;
        }
        onRunningChanged: {
            if (!running) {
                dragon.x = 0;
                dragon.y = 0;
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
