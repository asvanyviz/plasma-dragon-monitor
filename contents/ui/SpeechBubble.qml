import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

Rectangle {
    id: bubble
    property int dragonState: 0
    property string alertText: ""
    property color baseColor: "#4CAF50"

    visible: dragonState >= 1 && plasmoid.configuration.showBubble && alertText !== ""

    width: Math.min(messageLabel.implicitWidth + 24, 280)
    height: messageLabel.implicitHeight + 20

    // Anchors should be set by the parent (ExpandedView)
    // anchors.bottom: parent.top
    // anchors.horizontalCenter: parent.horizontalCenter

    color: Qt.rgba(
        Kirigami.Theme.backgroundColor.r * 0.7 + baseColor.r * 0.3,
        Kirigami.Theme.backgroundColor.g * 0.7 + baseColor.g * 0.3,
        Kirigami.Theme.backgroundColor.b * 0.7 + baseColor.b * 0.3,
        0.85
    )
    border.color: baseColor
    border.width: 2
    radius: 12

    // Arrow pointing down to dragon
    Canvas {
        width: 16
        height: 10
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = bubble.border.color;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(8, 10);
            ctx.lineTo(16, 0);
            ctx.closePath();
            ctx.fill();
        }
    }

    Label {
        id: messageLabel
        anchors.centerIn: parent
        text: alertText
        color: Kirigami.Theme.textColor
        wrapMode: Text.WordWrap
        maximumLineCount: 5
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: 10
    }

    // Fade in/out
    opacity: visible ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }
}
