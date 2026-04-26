import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: expandedView
    width: 256
    height: 320

    DragonCharacter {
        id: bigDragon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 20
        width: 128
        height: 128
        dragonState: root.currentState
        animationSpeed: plasmoid.configuration.animationSpeed || 1.0
    }

    SpeechBubble {
        anchors.bottom: bigDragon.top
        anchors.horizontalCenter: bigDragon.horizontalCenter
        anchors.bottomMargin: 10
        dragonState: root.currentState
        alertText: root.alertText
        baseColor: bigDragon.baseColor
    }

    // Fallback message when no data
    Label {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 10
        text: i18n("System data unavailable")
        visible: !root.dataAvailable
        opacity: 0.6
        font.pointSize: 8
        color: Kirigami.Theme.textColor
    }
}
