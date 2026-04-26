import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: compactView
    width: plasmoid.width
    height: plasmoid.height

    DragonCharacter {
        id: miniDragon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.85
        height: width
        dragonState: root.currentState
        animationSpeed: plasmoid.configuration.animationSpeed || 1.0
    }

    // Tooltip on hover
    ToolTip {
        text: root.dataAvailable ? stateEngine.summaryText : i18n("No system data available")
        visible: mouseArea.containsMouse
        delay: 500
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
