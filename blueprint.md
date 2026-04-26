# Plasma Dragon System Monitor Widget — Fejlesztési Blueprint (v2)

## 1. Architektúra áttekintés

### 1.1 Komponensek (QML-only)

```
┌─────────────────────────────────────────────────────────────┐
│                     Plasma Dragon Widget                     │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  DragonCharacter.qml              │    │ SpeechBubble │  │
│  │  (SVG + currentColor tint)        │    │   (Asztal)   │  │
│  │  • Sárkány test                   │    │  • Metrika   │  │
│  │  • Animációk (légzés, farok)      │    │    szövegek  │  │
│  │                                   │    │  • Animált   │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                   │                    │          │
│  ┌──────▼───────┐    ┌──────▼───────┐    ┌──────▼───────┐  │
│  │  StateEngine │    │   Animator   │    │ LayoutEngine │  │
│  │  (JS logic)  │    │   (QML)      │    │  (compact vs │  │
│  │  • Metrika   │    │  • Breathing │    │   expanded)  │  │
│  │    szűrés    │    │  • Blinking  │    │              │  │
│  │  • Hiszterézis│   │  • Tail wag  │    │              │  │
│  │  • Szín      │    │  • Wing flap │    │              │  │
│  │    interpolál│    │  • Shake     │    │              │  │
│  └──────┬───────┘    └──────────────┘    └──────────────┘  │
│         │                                                   │
│  ┌──────▼───────┐    ┌──────────────────────────────────┐  │
│  │ ConfigModel  │    │    PlasmaCore.DataSource          │  │
│  │  (QML + KCM) │    │    • systemmonitor engine         │  │
│  │  • Küszöbök  │    │    • CPU, RAM, Disk, Temp, Net    │  │
│  │  • Színek    │    │    • 1000ms update interval       │  │
│  │  • Metrikák  │    │    • Error handling               │  │
│  │  • Anim      │    └──────────────────────────────────┘  │
│  │    sebesség  │                                           │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Adatfolyam

```
PlasmaCore.DataSource (systemmonitor engine)
       │
       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ StateEngine  │────▶│ Dragon       │────▶│ SpeechBubble │
│ (JS logic)   │     │ Character    │     │ (asztal mód) │
│              │     │ (QML)        │     │              │
│ • Szűrés     │     │              │     │ • Probléma   │
│ • Hiszterézis│     │ • SVG        │     │   leírás     │
│ • Szín       │     │ • currentColor│    │ • Fade in/out│
│   interpolál │     │ • Animációk  │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## 2. Fájlstruktúra

```
plasma-dragon-system-monitor/
├── metadata.json              # Plasmoid manifest
├── contents/
│   ├── config/
│   │   └── main.xml           # KConfigXT séma
│   ├── ui/
│   │   ├── main.qml           # Root — PlasmoidItem + DataSource
│   │   ├── CompactView.qml    # Panel mód (22-64px)
│   │   ├── ExpandedView.qml   # Asztal mód (128px+)
│   │   ├── DragonCharacter.qml # Sárkány (SVG + animációk)
│   │   ├── SpeechBubble.qml   # Szövegbuborék
│   │   ├── StateEngine.qml    # Állapot számítás + hiszterézis
│   │   └── ConfigGeneral.qml  # KCM config UI
│   └── images/
│       └── dragon.svg         # Egy SVG — currentColor színezés
├── CMakeLists.txt             # Build + i18n
└── po/                        # Fordítások
    └── hu.po                  # Magyar fordítás
```

---

## 3. QML Komponensek részletesen

### 3.1 main.qml — Root + DataSource

```qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
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
        
        // Fallback ha nincs adat
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
}
```

### 3.2 DragonCharacter.qml — SVG + Animációk

```qml
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
        }
    }
    
    // Egy SVG — currentColor színezéssel
    Image {
        id: dragonImage
        source: "../images/dragon.svg"
        sourceSize: Qt.size(parent.width, parent.height)
        anchors.fill: parent
        
        // SVG színezése: a dragon.svg "currentColor" CSS változót használ
        // Qt-ben: a color property bindinggal állítjuk
    }
    
    // Glow effekt (critical) — Rectangle shadow helyett egyszerű opacity pulse
    Rectangle {
        id: glowRect
        anchors.fill: parent
        color: dragon.baseColor
        radius: width / 2
        opacity: dragonState === 3 ? glowAnim.opacity : 0
        visible: dragonState === 3
        
        SequentialAnimation {
            id: glowAnim
            property real opacity: 0.3
            loops: Animation.Infinite
            running: dragonState === 3
            
            NumberAnimation { target: glowRect; property: "opacity"; to: 0.6; duration: 500/dragon.animationSpeed }
            NumberAnimation { target: glowRect; property: "opacity"; to: 0.2; duration: 500/dragon.animationSpeed }
        }
    }
    
    // Animációk — lásd 5. fejezet
    DragonAnimator {
        target: dragonImage
        state: dragonState
        speed: animationSpeed
    }
}
```

### 3.3 SpeechBubble.qml — Asztal mód

```qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Rectangle {
    id: bubble
    visible: dragonState >= 1 && plasmoid.configuration.showBubble && alertText !== ""
    
    width: Math.min(messageLabel.implicitWidth + 20, 300)
    height: messageLabel.implicitHeight + 20
    
    // Egyszerű pozicionálás: dragon felett, középre igazítva
    anchors.bottom: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 10
    
    color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, baseColor, 0.3)
    border.color: baseColor
    border.width: 2
    radius: 10
    
    // Nyíl a dragon felé
    Canvas {
        width: 16; height: 10
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
    }
    
    // Megjelenés / eltűnés
    Behavior on opacity { NumberAnimation { duration: 300 } }
    opacity: visible ? 1 : 0
}
```

### 3.4 CompactView.qml — Panel mód

```qml
import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    width: plasmoid.width
    height: plasmoid.height
    
    DragonCharacter {
        id: miniDragon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.8
        height: width
        dragonState: root.currentState
        animationSpeed: plasmoid.configuration.animationSpeed || 1.0
    }
    
    // Tooltip — részletes metrikák hover-re
    ToolTip {
        text: root.dataAvailable ? stateEngine.summaryText : i18n("No data available")
        visible: mouseArea.containsMouse
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
```

### 3.5 ExpandedView.qml — Asztal mód

```qml
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
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
        dragonState: root.currentState
        alertText: root.alertText
        baseColor: bigDragon.baseColor
    }
    
    // Fallback üzenet ha nincs adat
    Label {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: i18n("System data unavailable")
        visible: !root.dataAvailable
        opacity: 0.6
        font.pointSize: 8
    }
}
```

### 3.6 StateEngine.qml — Hiszterézis + Szűrés

```qml
import QtQuick 2.15

QtObject {
    id: engine
    
    property var dataSource: null
    property var thresholds: {}
    property var enabledMetrics: []
    property bool dataAvailable: true
    
    property int currentState: 0  // 0=calm, 1=alert, 2=angry, 3=critical
    property string alertText: ""
    property string summaryText: ""
    
    // Adatok feldolgozása DataSource-ból
    function updateMetrics() {
        if (!dataSource || !dataSource.data) {
            dataAvailable = false;
            return;
        }
        
        var metrics = [];
        var data = dataSource.data;
        
        for (var source in data) {
            if (!enabledMetrics.includes(source)) continue;
            var value = data[source].value || 0;
            metrics.push({ id: source, name: getMetricName(source), value: value });
        }
        
        if (metrics.length === 0) {
            dataAvailable = false;
            return;
        }
        
        dataAvailable = true;
        
        // Legmagasabb terhelés
        var maxLoad = 0;
        var worstMetric = null;
        for (var i = 0; i < metrics.length; i++) {
            if (metrics[i].value > maxLoad) {
                maxLoad = metrics[i].value;
                worstMetric = metrics[i];
            }
        }
        
        // Hiszterézis — enter/exit threshold-ok
        var newState = currentState;
        
        if (currentState >= 3 && maxLoad < thresholds.exitCritical) newState = 2;
        else if (currentState >= 2 && maxLoad < thresholds.exitAngry) newState = 1;
        else if (currentState >= 1 && maxLoad < thresholds.exitAlert) newState = 0;
        
        if (maxLoad >= thresholds.enterCritical) newState = 3;
        else if (maxLoad >= thresholds.enterAngry) newState = 2;
        else if (maxLoad >= thresholds.enterAlert) newState = 1;
        else newState = 0;
        
        currentState = newState;
        
        // Alert szöveg generálás
        var issues = [];
        for (var j = 0; j < metrics.length; j++) {
            if (metrics[j].value >= thresholds.enterAlert) {
                issues.push(i18n("%1: %2%", metrics[j].name, Math.round(metrics[j].value)));
            }
        }
        alertText = issues.join("\n");
        
        // Summary tooltip szöveg
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
    
    // Timer az adatok feldolgozására
    Timer {
        interval: 1000
        running: engine.dataSource !== null
        repeat: true
        onTriggered: engine.updateMetrics()
    }
    
    // Figyelés DataSource változásra
    Connections {
        target: engine.dataSource
        onDataChanged: engine.updateMetrics()
    }
}
```

### 3.7 ConfigGeneral.qml — KCM UI

```qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.config as KConfig

KCM.SimpleKCM {
    title: i18n("Dragon System Monitor")
    
    Kirigami.FormLayout {
        // Metrikák szekció
        Kirigami.Heading { text: i18n("Monitored Metrics") }
        
        CheckBox {
            Kirigami.FormLayout.label: i18n("CPU Usage")
            checked: plasmoid.configuration.monitorCpu
            onCheckedChanged: plasmoid.configuration.monitorCpu = checked
        }
        CheckBox {
            Kirigami.FormLayout.label: i18n("RAM Usage")
            checked: plasmoid.configuration.monitorRam
            onCheckedChanged: plasmoid.configuration.monitorRam = checked
        }
        CheckBox {
            Kirigami.FormLayout.label: i18n("Disk I/O")
            checked: plasmoid.configuration.monitorDisk
            onCheckedChanged: plasmoid.configuration.monitorDisk = checked
        }
        CheckBox {
            Kirigami.FormLayout.label: i18n("Temperature")
            checked: plasmoid.configuration.monitorTemp
            onCheckedChanged: plasmoid.configuration.monitorTemp = checked
        }
        CheckBox {
            Kirigami.FormLayout.label: i18n("Network")
            checked: plasmoid.configuration.monitorNet
            onCheckedChanged: plasmoid.configuration.monitorNet = checked
        }
        
        // Küszöbértékek — hiszterézis (enter/exit)
        Kirigami.Heading { text: i18n("Thresholds (%)") }
        
        SpinBox {
            Kirigami.FormLayout.label: i18n("Alert enter")
            value: plasmoid.configuration.thresholdEnterAlert
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdEnterAlert = value
        }
        SpinBox {
            Kirigami.FormLayout.label: i18n("Alert exit")
            value: plasmoid.configuration.thresholdExitAlert
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdExitAlert = value
        }
        
        SpinBox {
            Kirigami.FormLayout.label: i18n("Angry enter")
            value: plasmoid.configuration.thresholdEnterAngry
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdEnterAngry = value
        }
        SpinBox {
            Kirigami.FormLayout.label: i18n("Angry exit")
            value: plasmoid.configuration.thresholdExitAngry
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdExitAngry = value
        }
        
        SpinBox {
            Kirigami.FormLayout.label: i18n("Critical enter")
            value: plasmoid.configuration.thresholdEnterCritical
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdEnterCritical = value
        }
        SpinBox {
            Kirigami.FormLayout.label: i18n("Critical exit")
            value: plasmoid.configuration.thresholdExitCritical
            from: 0; to: 100
            onValueModified: plasmoid.configuration.thresholdExitCritical = value
        }
        
        // Színek
        Kirigami.Heading { text: i18n("Colors") }
        
        // TODO: ColorButton helyett egyszerűbb megoldás
        // (Plasma 6-ban a color picker widget eltérő lehet)
        
        // Viselkedés
        Kirigami.Heading { text: i18n("Behavior") }
        
        SpinBox {
            Kirigami.FormLayout.label: i18n("Update interval (ms)")
            value: plasmoid.configuration.updateInterval
            from: 500; to: 10000; stepSize: 100
            onValueModified: plasmoid.configuration.updateInterval = value
        }
        CheckBox {
            Kirigami.FormLayout.label: i18n("Show speech bubble")
            checked: plasmoid.configuration.showBubble
            onCheckedChanged: plasmoid.configuration.showBubble = checked
        }
    }
}
```

---

## 4. Data Source (QML-only)

### 4.1 PlasmaCore.DataSource

**Nincs szükség C++ backendre.** A Plasma 6 `systemmonitor` data engine natívan biztosítja a metrikákat.

```qml
PlasmaCore.DataSource {
    id: sysMonitor
    engine: "systemmonitor"
    connectedSources: ["cpu/all/usage", "memory/physical/usedPercent"]
    interval: 1000
}
```

### 4.2 Engine sources (Plasma 6)

| Metrika | Source | Érték | Megjegyzés |
|---------|--------|-------|------------|
| CPU | `cpu/all/usage` | 0-100% | Átlagos CPU használat |
| RAM | `memory/physical/usedPercent` | 0-100% | Fizikai memória használat |
| Disk | `disk/all/readWriteRate` | MB/s | Összesített I/O |
| Temp | `acpi/Thermal_Zone/0/Temperature` | °C | Első thermal zone |
| Network | `network/all/receivedDataRate` | KB/s | Bejövő adat |

**Megjegyzés:** A source nevek disztribúció és hardver függőek lehetnek. Error handling kötelező.

---

## 5. Animációs logika

### 5.1 Animációk táblázata

| Animáció | Nyugodt | Éber | Haragos | Kritikus | Implementáció |
|----------|---------|------|---------|----------|---------------|
| **Légzés** | 3s, mély | 2s, közepes | 1s, felületes | 0.8s, szaggatott | Scale Y |
| **Pislogás** | 5-8s random | 3-5s random | 2-3s random | 1-2s random | SVG váltás |
| **Farok** | Lassú hinta | Gyorsabb hinta | Erős csapkodás | Vadul csapkodó | Rotation |
| **Szárnyak** | Nyugalom | Enyhén mozgó | Csapkodó | Gyors csapkodás | Rotation |
| **Vibrálás** | — | — | 2px | 5px | Random offset |
| **Glow** | Nincs | Nincs | Enyhe | Erős, pulzáló | Opacity pulse |

### 5.2 DragonAnimator.qml

```qml
Item {
    id: animator
    property Item target
    property int state: 0
    property real speed: 1.0
    
    // Légzés
    SequentialAnimation {
        loops: Animation.Infinite
        running: true
        NumberAnimation {
            target: animator.target
            property: "scale"
            to: state <= 1 ? 1.05 : 1.12
            duration: (state === 0 ? 3000 : state === 1 ? 2000 : 1000) / speed
        }
        NumberAnimation {
            target: animator.target
            property: "scale"
            to: 1.0
            duration: (state === 0 ? 3000 : state === 1 ? 2000 : 1000) / speed
        }
    }
    
    // Pislogás
    Timer {
        interval: Math.random() * 3000 + (state === 0 ? 5000 : 2000)
        running: true
        repeat: true
        onTriggered: {
            // SVG layer váltás vagy opacity
        }
    }
    
    // Farok hintázás
    RotationAnimation {
        target: animator.target
        property: "rotation"
        from: -10; to: 10
        duration: (state === 0 ? 2000 : state === 1 ? 1200 : 600) / speed
        direction: RotationAnimation.Alternate
        loops: Animation.Infinite
        running: true
    }
    
    // Vibrálás (angry + critical)
    Timer {
        interval: 50
        running: state >= 2
        repeat: true
        onTriggered: {
            var intensity = state === 2 ? 2 : 4;
            animator.target.x = (Math.random() - 0.5) * intensity;
            animator.target.y = (Math.random() - 0.5) * intensity;
        }
    }
}
```

### 5.3 SVG — currentColor használata

A `dragon.svg` fájlban a színezendő részek `currentColor` CSS kulcsszót használnak:

```svg
<svg xmlns="http://www.w3.org/2000/svg">
  <style>
    .dragon-body { fill: currentColor; }
  </style>
  <path class="dragon-body" d="..."/>
</svg>
```

Qt-ben a `Image` komponens `color` property-je nem működik SVG-re. Megoldások:
1. **Kirigami.Icon** — támogatja a színezést
2. **PlasmaCore.IconItem** — `color` property
3. **ShaderEffectSource** — ha szükséges

MVP-ben használjuk: `PlasmaCore.IconItem` vagy több SVG fájl (calm/alert/angry/critical).

---

## 6. Szín- és állapotkezelés

### 6.1 Hiszterézis (enter/exit threshold-ok)

```
           enterAlert                    enterAngry                 enterCritical
Calm ───────▶ Alert ────────────────────▶ Angry ───────────────────▶ Critical
     ◀─────── exitAlert         ◀─────── exitAngry        ◀─────── exitCritical
```

### 6.2 Példa threshold-ok

| Állapot | Enter | Exit | Megjegyzés |
|---------|-------|------|------------|
| Alert | 70% | 60% | CPU 70%+ → alert; 60%- alatt → calm |
| Angry | 85% | 75% | CPU 85%+ → angry; 75%- alatt → alert |
| Critical | 95% | 90% | CPU 95%+ → critical; 90%- alatt → angry |

---

## 7. Szövegbuborék logika

### 7.1 Megjelenési szabályok

```qml
visible: expandedView && 
         config.showBubble && 
         stateEngine.currentState >= 1 && 
         stateEngine.alertText !== ""
```

### 7.2 Pozicionálás

- Egyszerű anchors: `anchors.bottom: dragon.top`
- Nincs szükség képernyő szélesség figyelésre — a Plasmoid konténer kezeli
- Ha a buborék kilógna felfelé: automatikusan alulra kerül (de az MVP-ben nem implementáljuk)

---

## 8. Konfiguráció

### 8.1 KConfigXT séma (main.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0">
    <kcfgfile name=""/>
    <group name="General">
        <!-- Metrikák -->
        <entry name="monitorCpu" type="Bool"><default>true</default></entry>
        <entry name="monitorRam" type="Bool"><default>true</default></entry>
        <entry name="monitorDisk" type="Bool"><default>false</default></entry>
        <entry name="monitorTemp" type="Bool"><default>false</default></entry>
        <entry name="monitorNet" type="Bool"><default>false</default></entry>
        
        <!-- Hiszterézis threshold-ok -->
        <entry name="thresholdEnterAlert" type="Int"><default>70</default></entry>
        <entry name="thresholdExitAlert" type="Int"><default>60</default></entry>
        <entry name="thresholdEnterAngry" type="Int"><default>85</default></entry>
        <entry name="thresholdExitAngry" type="Int"><default>75</default></entry>
        <entry name="thresholdEnterCritical" type="Int"><default>95</default></entry>
        <entry name="thresholdExitCritical" type="Int"><default>90</default></entry>
        
        <!-- Színek -->
        <entry name="colorCalm" type="Color"><default>#4CAF50</default></entry>
        <entry name="colorAlert" type="Color"><default>#FFEB3B</default></entry>
        <entry name="colorAngry" type="Color"><default>#FF9800</default></entry>
        <entry name="colorCritical" type="Color"><default>#F44336</default></entry>
        
        <!-- Viselkedés -->
        <entry name="animationSpeed" type="Double"><default>1.0</default></entry>
        <entry name="showBubble" type="Bool"><default>true</default></entry>
        <entry name="updateInterval" type="Int"><default>1000</default></entry>
    </group>
</kcfg>

### 8.2 metadata.json

```json
{
    "KPackageStructure": "Plasma/Applet",
    "KPlugin": {
        "Authors": [
            {
                "Email": "dev@example.com",
                "Name": "Developer"
            }
        ],
        "Category": "System Information",
        "Description": "Animated dragon system monitor widget",
        "Icon": "preferences-system-performance",
        "Id": "org.kde.plasma.dragon-monitor",
        "License": "GPL-2.0+",
        "Name": "Dragon System Monitor",
        "Version": "1.0.0",
        "Website": "https://github.com/asvanyviz/plasma-dragon-monitor"
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-ConfigurationFile": "plasma-dragon-monitor",
    "X-Plasma-ConfigurationUI": "ui/ConfigGeneral.qml",
    "X-Plasma-DefaultSize": "256,320"
}
```

---

## 9. Telepítés és tesztelés

### 9.1 Build és telepítés

```bash
# 1. Clone
# 2. Build
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make

# 3. Telepítés (user-local)
kpackagetool6 --install .. --type Plasma/Applet
# vagy frissítés:
kpackagetool6 --upgrade .. --type Plasma/Applet
```

### 9.2 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(plasma-dragon-monitor VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml)
find_package(KF6 REQUIRED COMPONENTS CoreAddons Config I18n)
find_package(Plasma REQUIRED)

plasma_install_package(package org.kde.plasma.dragon-monitor)
ki18n_install(po)
```

### 9.3 Tesztelési forgatókönyvek

| # | Forgatókönyv | Ellenőrzendő | Módszer |
|---|-------------|-------------|---------|
| 1 | Panel mód | Kompakt sárkány, szín változik | Widget hozzáadása panelhez |
| 2 | Asztal mód | Nagy sárkány + buborék | Widget hozzáadása asztalhoz |
| 3 | CPU terhelés | Állapotváltás zöld → sárga → narancs → vörös | `stress-ng -c 4` |
| 4 | RAM terhelés | Buborék megjelenik | Nagy memória alloc |
| 5 | Normalizálódás | Vissza nyugodt állapot | Terhelés leállítása |
| 6 | Konfigurálás | Színek, küszöbök módosulnak | System Settings → Widget |
| 7 | Hiszterézis | Nem villog a határértéken | Threshold határán teszt |
| 8 | Buborék ki/be | Megjelenik/eltűnik | Config checkbox |
| 9 | Error handling | Üzenet ha nincs adat | DataSource leállítása |
| 10 | i18n | Magyar szövegek | `LANG=hu_HU.UTF-8` |

### 9.4 Debug mód

```qml
// main.qml-ban
property bool debugMode: Qt.application.arguments.indexOf("--debug") !== -1

Rectangle {
    visible: debugMode
    color: "black"
    opacity: 0.8
    Column {
        Label { text: "State: " + stateEngine.currentState }
        Label { text: "Alert: " + stateEngine.alertText }
        Label { text: "Data: " + stateEngine.dataAvailable }
    }
}
```

---

## 10. Plasma 6 specifikumok

### 10.1 Import sorok

```qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM
```

### 10.2 API változások Plasma 5 → 6

| Komponens | Plasma 5 | Plasma 6 |
|-----------|----------|----------|
| Root | `PlasmaCore.Item` | `PlasmoidItem` |
| DataSource | `Plasma5Support.DataSource` | `PlasmaCore.DataSource` |
| compactRepresentation | Ezek a property-k | Megegyeznek |
| Kirigami | `import org.kde.kirigami 2.12` | `import org.kde.kirigami 2.20` |
| KCM | `KDeclarative` | `KCM.SimpleKCM` |
| kpackagetool | `kpackagetool5` | `kpackagetool6` |

### 10.3 Gyakori buktatók

1. **DataSource engine nevek** — Plasma 6-ban `systemmonitor` (nem `systemmonitor2`)
2. **Source hierarchia** — `cpu/all/usage` (nem `cpu/system/AverageClock`)
3. **Kirigami Units** — `Kirigami.Units` helyett `PlasmaCore.Units`
4. **Theme** — `PlasmaCore.Theme`
5. **C++ plugin** — Nem szükséges, QML-only megoldás elegendő

---

## 11. MVP Scope (első iteráció)

### MUST HAVE:
- [ ] Panel + desktop működő megjelenítés
- [ ] CPU + RAM monitorozás (systemmonitor data engine)
- [ ] 4 állapot szín- és animációváltással (légzés + pislogás)
- [ ] Szövegbuborék asztal módban
- [ ] Alap konfig (threshold-ok, színek, sensor választás)
- [ ] Hiszterézis (enter/exit threshold-ok)
- [ ] Error handling (DataSource nem elérhető)

### SHOULD HAVE:
- [ ] Farok/szárny animációk
- [ ] i18n alap (magyar + angol)
- [ ] Disk I/O, hőmérséklet

### COULD HAVE (Phase 2+):
- [ ] Hálózat monitorozás
- [ ] Egyedi dragon kinézetek (skin-ek)
- [ ] Glow effekt (critical state)
- [ ] Particle tűz effekt

---

## 12. Referenciák

- [Plasma 6 Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [Plasma 6 API Documentation](https://api.kde.org/plasma/plasma-framework/)
- [Kirigami Documentation](https://develop.kde.org/docs/kirigami/)
- [KConfigXT Documentation](https://api.kde.org/frameworks/kconfig/html/kconfig_xt.html)
- [libksysguard](https://invent.kde.org/plasma/libksysguard)
- [Plasma 6 Port Guide](https://develop.kde.org/docs/plasma/porting/)
