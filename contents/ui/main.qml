import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactView { }
    fullRepresentation: ExpandedView { }

    // Plasma 6 DataSource — systemmonitor engine
    PlasmaCore.DataSource {
        id: sysMonitor
        engine: "systemmonitor"
        connectedSources: {
            var sources = [];
            if (plasmoid.configuration.monitorCpu) sources.push("cpu/all/usage");
            if (plasmoid.configuration.monitorRam) sources.push("memory/physical/usedPercent");
            if (plasmoid.configuration.monitorDisk) sources.push("disk/all/readWriteRate");
            if (plasmoid.configuration.monitorTemp) sources.push("acpi/Thermal_Zone/0/Temperature");
            if (plasmoid.configuration.monitorNet) sources.push("network/all/receivedDataRate");
            return sources.length > 0 ? sources : ["cpu/all/usage"];
        }
        interval: plasmoid.configuration.updateInterval || 1000

        onError: {
            console.warn("DragonMonitor: DataSource error:", error);
            stateEngine.dataAvailable = false;
        }
        onDataChanged: stateEngine.dataAvailable = true

        onConnectedSourcesChanged: {
            if (connectedSources.length === 0) {
                stateEngine.dataAvailable = false;
            }
        }
    }

    // State engine
    StateEngine {
        id: stateEngine
        dataSource: sysMonitor
        thresholds: {
            "enterAlert": plasmoid.configuration.thresholdEnterAlert || 70,
            "exitAlert": plasmoid.configuration.thresholdExitAlert || 60,
            "enterAngry": plasmoid.configuration.thresholdEnterAngry || 85,
            "exitAngry": plasmoid.configuration.thresholdExitAngry || 75,
            "enterCritical": plasmoid.configuration.thresholdEnterCritical || 95,
            "exitCritical": plasmoid.configuration.thresholdExitCritical || 90
        }
        enabledMetrics: {
            var metrics = [];
            if (plasmoid.configuration.monitorCpu) metrics.push("cpu/all/usage");
            if (plasmoid.configuration.monitorRam) metrics.push("memory/physical/usedPercent");
            if (plasmoid.configuration.monitorDisk) metrics.push("disk/all/readWriteRate");
            if (plasmoid.configuration.monitorTemp) metrics.push("acpi/Thermal_Zone/0/Temperature");
            if (plasmoid.configuration.monitorNet) metrics.push("network/all/receivedDataRate");
            return metrics;
        }
    }

    // Global properties
    property int currentState: stateEngine.currentState
    property string alertText: stateEngine.alertText
    property bool dataAvailable: stateEngine.dataAvailable

    // Debug overlay (enabled with --debug)
    property bool debugMode: Qt.application.arguments.indexOf("--debug") !== -1

    Rectangle {
        visible: debugMode && root.dataAvailable
        anchors.fill: parent
        color: "black"
        opacity: 0.7
        z: 100

        Column {
            anchors.fill: parent
            padding: 10
            spacing: 5

            Label { text: "State: " + stateEngine.currentState; color: "lime" }
            Label { text: "Alert: " + stateEngine.alertText; color: "lime" }
            Label { text: "Summary: " + stateEngine.summaryText; color: "lime" }
            Label { text: "Data: " + stateEngine.dataAvailable; color: "lime" }
            Label { text: "Sources: " + sysMonitor.connectedSources; color: "lime" }
        }
    }
}
