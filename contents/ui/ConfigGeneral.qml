import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    title: i18n("Dragon System Monitor")

    Kirigami.FormLayout {
        
        ComboBox {
            Kirigami.FormData.label: i18n("Character:")
            model: ["Dragon", "Cat", "Dog"]
            currentIndex: model.indexOf(plasmoid.configuration.characterType || "Dragon")
            onActivated: {
                plasmoid.configuration.characterType = model[index];
            }
            // Could be dynamically built by scanning ../images/ for SVGs
        }

        Kirigami.Heading {
            text: i18n("Monitored Metrics")
            level: 2
        }

        CheckBox {
            Kirigami.FormData.label: i18n("CPU Usage:")
            checked: plasmoid.configuration.monitorCpu
            onCheckedChanged: plasmoid.configuration.monitorCpu = checked
        }
        CheckBox {
            Kirigami.FormData.label: i18n("RAM Usage:")
            checked: plasmoid.configuration.monitorRam
            onCheckedChanged: plasmoid.configuration.monitorRam = checked
        }
        CheckBox {
            Kirigami.FormData.label: i18n("Disk I/O:")
            checked: plasmoid.configuration.monitorDisk
            onCheckedChanged: plasmoid.configuration.monitorDisk = checked
        }
        CheckBox {
            Kirigami.FormData.label: i18n("Temperature:")
            checked: plasmoid.configuration.monitorTemp
            onCheckedChanged: plasmoid.configuration.monitorTemp = checked
        }
        CheckBox {
            Kirigami.FormData.label: i18n("Network:")
            checked: plasmoid.configuration.monitorNet
            onCheckedChanged: plasmoid.configuration.monitorNet = checked
        }

        Kirigami.Heading {
            text: i18n("Thresholds (%)")
            level: 2
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Alert enter:")
            value: plasmoid.configuration.thresholdEnterAlert
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdEnterAlert = value
        }
        SpinBox {
            Kirigami.FormData.label: i18n("Alert exit:")
            value: plasmoid.configuration.thresholdExitAlert
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdExitAlert = value
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Angry enter:")
            value: plasmoid.configuration.thresholdEnterAngry
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdEnterAngry = value
        }
        SpinBox {
            Kirigami.FormData.label: i18n("Angry exit:")
            value: plasmoid.configuration.thresholdExitAngry
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdExitAngry = value
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Critical enter:")
            value: plasmoid.configuration.thresholdEnterCritical
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdEnterCritical = value
        }
        SpinBox {
            Kirigami.FormData.label: i18n("Critical exit:")
            value: plasmoid.configuration.thresholdExitCritical
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdExitCritical = value
        }

        Kirigami.Heading {
            text: i18n("Behavior")
            level: 2
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Update interval (ms):")
            value: plasmoid.configuration.updateInterval
            from: 500; to: 10000; stepSize: 100
            onValueModified: plasmoid.configuration.updateInterval = value
        }
        CheckBox {
            Kirigami.FormData.label: i18n("Show speech bubble:")
            checked: plasmoid.configuration.showBubble
            onCheckedChanged: plasmoid.configuration.showBubble = checked
        }
    }
}
