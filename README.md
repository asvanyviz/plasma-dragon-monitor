# 🐉 Dragon System Monitor

A KDE Plasma 6 widget that displays an animated dragon whose mood reflects your system's load. Inspired by the catwalk widget, but with more personality and features.

## Features

- **Dual mode**: Compact panel icon or full desktop widget
- **Animated dragon**: Breathing, blinking, tail wag, and shake animations
- **4 states**: Calm → Alert → Angry → Critical (with hysteresis to prevent flickering)
- **Speech bubble**: Desktop mode shows which metrics are causing trouble
- **Configurable**: Choose which metrics to monitor (CPU, RAM, Disk, Temperature, Network)
- **QML-only**: No C++ backend needed, uses Plasma's native `systemmonitor` data engine

## Screenshots

*(Coming soon)*

## Installation

### Requirements
- KDE Plasma 6
- `kpackagetool6`

### Build & Install

```bash
git clone https://github.com/asvanyviz/plasma-dragon-monitor.git
cd plasma-dragon-monitor
mkdir build && cd build
cmake ..
make
kpackagetool6 --install .. --type Plasma/Applet
```

Or for quick testing without building:

```bash
mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.dragon-monitor
cp -r contents metadata.json ~/.local/share/plasma/plasmoids/org.kde.plasma.dragon-monitor/
# Then restart Plasma: killall plasmashell && kstart plasmashell
```

### Upgrade

```bash
cd plasma-dragon-monitor/build
make
kpackagetool6 --upgrade .. --type Plasma/Applet
```

## Configuration

Right-click the widget → **Configure Dragon System Monitor**

- **Monitored Metrics**: Toggle CPU, RAM, Disk I/O, Temperature, Network
- **Thresholds**: Set enter/exit values for each state (hysteresis prevents flickering)
- **Colors**: Customize the dragon's color for each state
- **Behavior**: Update interval, animation speed, speech bubble toggle

## Development

### File Structure

```
.
├── metadata.json              # Plasmoid manifest
├── CMakeLists.txt             # Build configuration
├── contents/
│   ├── config/
│   │   └── main.xml           # KConfigXT schema
│   ├── ui/
│   │   ├── main.qml           # Root PlasmoidItem + DataSource
│   │   ├── CompactView.qml    # Panel mode (22-64px)
│   │   ├── ExpandedView.qml   # Desktop mode (128px+)
│   │   ├── DragonCharacter.qml # Animated dragon
│   │   ├── SpeechBubble.qml   # Alert bubble
│   │   ├── StateEngine.qml    # State calculation + hysteresis
│   │   └── ConfigGeneral.qml  # Settings UI
│   └── images/
│       └── dragon.svg         # Dragon graphic
└── po/                        # Translations
```

### Architecture

```
PlasmaCore.DataSource (systemmonitor engine)
       │
       ▼
StateEngine (JS) ──▶ DragonCharacter (QML) ──▶ SpeechBubble (QML)
  • Hysteresis         • SVG + animations        • Alert text
  • Metric filtering   • Color changes           • Fade in/out
```

### Testing Load

```bash
# CPU stress
stress-ng -c 4 --timeout 60

# RAM stress
stress-ng --vm 2 --vm-bytes 80% --timeout 60
```

## Roadmap

- [ ] Better dragon SVG (art contributions welcome!)
- [ ] Wing flap animation
- [ ] Glow/pulse effect for critical state
- [ ] Particle fire effect (optional)
- [ ] More sensor sources (GPU, swap, etc.)
- [ ] Custom dragon skins

## License

GPL-2.0+

## Credits

Created by Zsolt Papp with help from the OpenClaw Minerva agent.
