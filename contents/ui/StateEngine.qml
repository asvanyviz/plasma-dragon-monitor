import QtQuick 2.15
import org.kde.kirigami 2.20 as Kirigami

QtObject {
    id: engine

    property var dataSource: null
    property var thresholds: {
        "enterAlert": 70,
        "exitAlert": 60,
        "enterAngry": 85,
        "exitAngry": 75,
        "enterCritical": 95,
        "exitCritical": 90
    }
    property var enabledMetrics: []
    property bool dataAvailable: true

    property int currentState: 0  // 0=calm, 1=alert, 2=angry, 3=critical
    property string alertText: ""
    property string summaryText: ""

    function updateMetrics() {
        if (!dataSource || !dataSource.data) {
            dataAvailable = false;
            return;
        }

        var metrics = [];
        var data = dataSource.data;

        for (var source in data) {
            if (enabledMetrics.indexOf(source) === -1) continue;
            var value = data[source].value || 0;
            metrics.push({ id: source, name: getMetricName(source), value: value });
        }

        if (metrics.length === 0) {
            dataAvailable = false;
            return;
        }

        dataAvailable = true;

        // Find highest load metric
        var maxLoad = 0;
        var worstMetric = null;
        for (var i = 0; i < metrics.length; i++) {
            if (metrics[i].value > maxLoad) {
                maxLoad = metrics[i].value;
                worstMetric = metrics[i];
            }
        }

        // Hysteresis — enter/exit thresholds
        // First: determine target state based on maxLoad
        var targetState = 0;
        if (maxLoad >= thresholds.enterCritical) targetState = 3;
        else if (maxLoad >= thresholds.enterAngry) targetState = 2;
        else if (maxLoad >= thresholds.enterAlert) targetState = 1;

        // Apply hysteresis: only drop state if exit threshold crossed
        var newState = currentState;
        if (targetState > currentState) {
            // Always allow moving up immediately
            newState = targetState;
        } else if (targetState < currentState) {
            // Only move down if we've crossed the exit threshold
            var exitThreshold = (currentState === 3) ? thresholds.exitCritical :
                                (currentState === 2) ? thresholds.exitAngry :
                                (currentState === 1) ? thresholds.exitAlert : 0;
            if (maxLoad < exitThreshold) {
                newState = targetState;
            }
        }

        currentState = newState;

        // Alert text generation
        var issues = [];
        for (var j = 0; j < metrics.length; j++) {
            if (metrics[j].value >= thresholds.enterAlert) {
                issues.push(i18n("%1: %2%", metrics[j].name, Math.round(metrics[j].value)));
            }
        }
        alertText = issues.join("\n");

        // Summary tooltip text
        var summary = [];
        for (var k = 0; k < metrics.length; k++) {
            summary.push(i18n("%1: %2%", metrics[k].name, Math.round(metrics[k].value)));
        }
        summaryText = summary.join(" | ");
    }

    function getMetricName(id) {
        var names = {
            "cpu/all/usage": i18n("CPU"),
            "memory/physical/usedPercent": i18n("RAM"),
            "disk/all/readWriteRate": i18n("Disk"),
            "acpi/Thermal_Zone/0/Temperature": i18n("Temp"),
            "network/all/receivedDataRate": i18n("Network")
        };
        return names[id] || id;
    }

    Timer {
        interval: 1000
        running: engine.dataSource !== null
        repeat: true
        onTriggered: engine.updateMetrics()
    }
}
