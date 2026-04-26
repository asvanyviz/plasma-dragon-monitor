import QtQuick 2.15

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
        var newState = currentState;

        if (currentState >= 3 && maxLoad < thresholds.exitCritical) newState = 2;
        else if (currentState >= 2 && maxLoad < thresholds.exitAngry) newState = 1;
        else if (currentState >= 1 && maxLoad < thresholds.exitAlert) newState = 0;

        if (maxLoad >= thresholds.enterCritical) newState = 3;
        else if (maxLoad >= thresholds.enterAngry) newState = 2;
        else if (maxLoad >= thresholds.enterAlert) newState = 1;
        else newState = 0;

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
