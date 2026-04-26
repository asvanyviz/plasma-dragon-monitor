import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

Rectangle {
    id: bubble
    visible: dragonState >= 1 && plasmoid.configuration.showBubble && alertText !== ""

    width: Math.min(messageLabel.implicitWidth + 24, 280)
    height: messageLabel.implicitHeight + 20

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter

    color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, baseColor, 0.3)
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
