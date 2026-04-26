# Aporia Review — Plasma Dragon System Monitor Widget

## 1. Általános értékelés

A blueprint átfogó és jól strukturált, de **több kritikus ponton pontatlan vagy elavult a Plasma 6 API-val kapcsolatban**. A C++ backend terv feleslegesen komplex, miközben a libksysguard integráció nincs megfelelően specifikálva. A speech bubble logika és a state engine alapvetően helyes, de a hiszterézis implementáció hibás lehet. Összességében **át kell dolgozni** a Plasma 6 specifikus részeket, és egyszerűsíteni az adatforrás architektúrát.

## 2. Konkrét problémák (sorrendben)

### P1 — ARCHITECTURE: Kettős/inkonzisztens adatforrás architektúra
- **Blueprint 1.2 és 4.x**: Egyidejűleg tervezi egy saját C++ `SystemStatsReader` backendet (proc filesystem olvasás) ÉS a `Plasma5Support.DataSource` libksysguard data engine-t.
- **Probléma**: Ez két párhuzamos adatforrás, konfliktus lehet, és a C++ backend túlzó egy plasmoid-hoz képest.
- **Következmény**: Felesleges komplexitás, karbantartási teher, és a Plasma 6-ban a `Plasma5Support.DataSource` engine nevek/hierarchia változott.

### P2 — TECHNOLOGY: Plasma 5 API hivatkozások Plasma 6 projektben
- **Blueprint 3.1**: `Plasma5Support.DataSource` szerepel a példában.
- **Blueprint 10.1**: "Plasma5Support.DataSource" → "Plasma6Support.DataSource" — ez téves. Plasma 6-ban a DataSource a `org.kde.plasma.core` modulból érhető el, nem külön "Plasma6Support" névtér.
- **Probléma**: A blueprint nem használja a valós Plasma 6 importokat. Ez build hibához vezet.

### P3 — TECHNOLOGY: C++ backend indokolatlansága
- **Blueprint 4.1**: Saját C++ plugin `SystemStatsReader`, `/proc/stat`, `/proc/meminfo` olvasása.
- **Probléma**: A libksysguard már biztosítja ezeket az adatokat stabilan. A `/proc/stat` CPU számítás nem triviális (idle vs iowait), és a hőmérséklet olvasás (`/sys/class/hwmon/*`) platform-specifikus.
- **Kockázat**: Hibás metrika számítás, memóriaszivárgás, Qt6/KF6 Plasma plugin buildelési problémák.

### P4 — STATE ENGINE: Hiszterézis logika hibás
- **Blueprint 6.2**: `getStateWithHysteresis` függvény.
```javascript
if (value >= thresholdsUp.angry) return State.Critical
if (value >= thresholdsUp.alert) return State.Angry
if (value >= thresholdsUp.calm)  return State.Alert
```
- **Probléma**: A `thresholdsUp` értékei: calm: 40, alert: 70, angry: 90. De a függvény szerint `>= 90` → Critical, `>= 70` → Angry, `>= 40` → Alert. Ez azt jelenti, hogy 45% CPU használatnál már Alert állapotba kerülünk, ami ellentmondás a 6.1 fejezetbeli ábrával (Nyugodt ≥40% → Éber). A küszöbértékek és az állapot mapping nincs összhangban.
- **Ellentmondás**: Az enum értékek: Calm=0, Alert=1, Angry=2, Critical=3. De a küszöbök nevei (calm, alert, angry) az értéket jelzik, nem az állapotot. Ez zavaró és hibalehetőséget rejt.

### P5 — STATE ENGINE: Állapot számítás nem kezeli a disabled metrikákat
- **Blueprint 3.6**: `StateEngine.recalculate()` végigmegy az összes metrikán.
- **Probléma**: Ha a user kikapcsolja a CPU-t a configban, de a `metrics` tömbben még benne van, az továbbra is befolyásolja az állapotot. A `recalculate` nem szűri a `metrics`-ot a `config` alapján.

### P6 — SPEECH BUBBLE: Buborék pozicionálás nem robust
- **Blueprint 7.2**: `calculatePosition()` a `Screen.width`-et használja.
- **Probléma**: Plasmoid-ok nem teljes képernyőn futnak; a widgetnek saját koordinátarendszere van. A `mapToItem(null, 0, 0)` az abszolút koordinátákat adja, de a speech bubble a plasmoidon belül van elhelyezve (anchors.bottom: parent.top). A "ne lógjon ki a képernyőről" logika így irreleváns, mert a plasmoid konténer korlátozza a méretet.
- **Következmény**: A pozicionálási logika túlbonyolított és valószínűleg nem működik megfelelően a Plasma layout rendszerében.

### P7 — UI: ColorOverlay és Glow effekt nem szabványos Plasma 6
- **Blueprint 3.2**: `ColorOverlay` és `Glow` QML elemek.
- **Probléma**: Ezek nem standard QtQuick vagy Plasma elemek. `ColorOverlay` a Qt Graphical Effects modulból való (import Qt5Compat.GraphicalEffects), és nem mindig elérhető/javasolt Plasma 6-ban. A `Glow` szintén nem standard.
- **Következmény**: Extra dependency, és a színezés SVG `currentColor` használatával sokkal egyszerűbben megoldható.

### P8 — FILE STRUCTURE: Túl bontott QML struktúra
- **Blueprint 2.0**: `DragonParts/` mappa külön `DragonHead.qml`, `DragonWings.qml`, stb.
- **Probléma**: Egy plasmoid-nál a túlzott modularizáció nehezebb karbantartást eredményez. Mivel egy SVG-s komponensről van szó, a részek külön QML-ben való szétszedése indokolatlan, ha az egész egy `Image` forrásváltással megoldható.
- **Javaslat**: Egy `DragonCharacter.qml` elég, a részek animációi property bindinggal vezérelhetők.

### P9 — CHECKLIST: Sorrend probléma C++ backenddel
- **Checklist 5.x**: A C++ backend (5.1–5.8) a checklist korai szakaszában van, de a "Alternatíva: KSysGuard DataSource" (5.9) csak a végén, opcionálisként.
- **Probléma**: A KSysGuard DataSource valójában a preferált, egyszerűbb út. A checklist „fő útvonalaként” a C++ backend szerepel, ami veszélyezteti az MVP időhatárait.

### P10 — CONFIG: KCM modul regisztráció hiányos
- **Blueprint 8.2**: `X-Plasma-ConfigurationUI` a `metadata.json`-ben.
- **Probléma**: Plasma 6-ban a KCM integrációhoz szükség van a `KPackageStructure`: "Plasma/Applet" mellett a megfelelő KCM regisztrációra, ami a blueprintben nem szerepel. A `ConfigGeneral.qml` csak a UI, de a KCM modul inicializálása (pl. `KCM.SimpleKCM`) nincs részletezve.

### P11 — MISSING: i18n és ki18n használat
- **Blueprint**: `i18n()` függvényt használ a szövegekhez.
- **Probléma**: Plasma 6-ban a `i18n` a `org.kde.kirigami` modulból importálandó, és a fordítási sablon generálás (`Messages.sh`) specifikus a KF6-hoz. A blueprint nem említi, hogy a CMakeLists.txt-ben szükség van `ki18n_install()` vagy `ecm_install_po_files()` hívásra.

### P12 — MISSING: Error handling és fallback
- **Blueprint**: Nincs specifikálva mi történik, ha a DataSource nem elérhető, vagy a `systemmonitor` engine nincs betöltve.
- **Probléma**: Ha a DataSource `connectedSources` hibás, a widget csendben nem fog működni. Szükség lenne egy fallback-re (pl. placeholder szöveg: "Nem érhető el rendszerinformáció").

## 3. Javasolt javítások

| # | Probléma | Javaslat | Prioritás |
|---|----------|----------|-----------|
| J1 | Kettős adatforrás (P1) | **Töröld a C++ backendet.** Használd a Plasma 6 `systemmonitor` data source-t (`org.kde.plasma.systemmonitor` data engine vagy a libksysguard QML modult). Egyetlen, tiszta QML megoldás elegendő. | Kritikus |
| J2 | Plasma 5 API hivatkozások (P2) | Cseréld `Plasma5Support.DataSource`-ot a valós Plasma 6 importra: `import org.kde.plasma.core as PlasmaCore` és `PlasmaCore.DataSource` (ha elérhető), vagy használd a `KSystemStats` QML API-t. Ellenőrizd a `org.kde.plasma.systemmonitor` data engine elérhetőségét Plasma 6-ban. | Kritikus |
| J3 | Hiszterézis logika (P4) | Újra kell írni: a küszöbök egyértelműen az **állapotba való belépés** és **kilépés** értékeit jelentsék. Példa: `enterAlert: 70`, `exitAlert: 60`. A jelenlegi `thresholdsUp/thresholdsDown` elnevezés zavaró. | Kritikus |
| J4 | Disabled metrikák szűrése (P5) | A `StateEngine.recalculate()` csak az enabled metrikákra számoljon. A `metrics` property helyett használj `activeMetrics`-et, ami a config és az elérhetőség alapján szűrt. | Magas |
| J5 | Speech bubble pozicionálás (P6) | Egyszerűsítsd: a speech bubble legyen az `ExpandedView`-ban `anchors.bottom: dragon.top`, nem kell képernyő szélesség figyelés. A Plasmoid konténer kezeli a clipinget. | Magas |
| J6 | ColorOverlay/Glow (P7) | Használj SVG `currentColor`-t a színezéshez, vagy a Plasma 6 `PlasmaCore.IconItem tinted` módját. A Glow effekt helyett használj egyszerű `Rectangle` shadow-t vagy `PlasmaCore.FrameSvgItem`-et. | Közepes |
| J7 | Túlbontott QML (P8) | Egyesítsd a `DragonParts/` fájlokat `DragonCharacter.qml`-be. A szárnyak/farok animációk property/rotation bindinggal vezérelhetők egy Image-on belül is. | Közepes |
| J8 | Checklist sorrend (P9) | A KSysGuard DataSource legyen az **alapértelmezett** (5.1), a C++ backend pedig opcionális/alternatíva (5.9). Az MVP kritikus útvonalba kerüljön a QML-only megoldás. | Magas |
| J9 | KCM regisztráció (P10) | Adj hozzá részletes KCM inicializálást: `KCM.SimpleKCM` gyökérelem, és a `metadata.json` mellé egy `kcmconfigs/` mappa ha szükséges, vagy használd a `PlasmoidItem` beépített `configurationRequired` tulajdonságát. | Közepes |
| J10 | i18n build (P11) | A `CMakeLists.txt`-be vegyél fel `find_package(KF6I18n)` és `ki18n_install(po)`. A `Messages.sh` helyett javasolt az `ECMPoQm` használata. | Közepes |
| J11 | Error handling (P12) | Adj hozzá `DataSource.onError` vagy `onDataChanged` guard-ot. Ha a data source nem elérhető, a sárkány nyugodt állapotban maradjon és egy subtle indicator mutassa az adathiányt. | Közepes |

## 4. Megjegyzések

- **SVG asset-ek**: A 4 különálló SVG (calm, alert, angry, critical) túlzó az MVP-hez. Egy alap SVG + szín overlay (vagy `currentColor`) elég a kezdeti iterációkhoz. A `dragon-blink.svg` overlay hasznos, de opcionális.
- **ParticleSystem (5.2 táblázat)**: A "Tűz effekt" ParticleSystem túlzó funkció egy system monitor widgethez. Javasolt a Phase 3-ból törölni, vagy egy egyszerű CSS/SVG animációra cserélni.
- **Plasma 5 visszafelé kompatibilitás (10.3)**: Több energia, mint haszon. Javasolt kizárólag Plasma 6-ra fókuszálni. Ha valóban szükség lesz rá, az legyen külön ág, nem a fő blueprint része.
- **Checklist MVP útvonal**: A javasolt MVP:
  ```
  metadata.json → main.xml (config) → main.qml → DataSource (KSysGuard) → StateEngine → ColorEngine → DragonCharacter (1 SVG) → CompactView + ExpandedView → Telepítés/teszt
  ```

## 5. Végső verdict

**⚠️ APPROVED WITH CHANGES**

A blueprint alapvető koncepciója (sárkány karakter + állapotmotor + speech bubble + system monitor) jó és megvalósítható. A problémák **nem elvi síkon**, hanem implementációs/technológiai pontatlanságok: a Plasma 6 API helytelen használata, a túlzott C++ komplexitás, és a hiszterézis logika hibája.

**Feltétel az approve-hoz:**
1. Javítandó: J1, J2, J3, J4, J8 (kritikus/magas prioritású javítások)
2. A C++ backend kikerül az MVP-ből — csak QML + DataSource
3. A hiszterézis logika újragondolása egyértelmű enter/exit küszöbökkel
4. A checklist frissítése az új, egyszerűsített architektúrára

Ha a fenti javítások megtörténnek, a blueprint alkalmas a fejlesztés megkezdésére.
