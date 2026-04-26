# Plasma Dragon Widget — Checklist (v2)

## Phase 0: Foundation (előkészületek)
- [x] **0.1** Task könyvtár struktúra létrehozása
- [ ] **0.2** Plasma 6 SDK ellenőrzése (`kpackagetool6`, `plasmashell` verzió)
- [ ] **0.3** Referencia plasmoid tanulmányozás (catwalk, system monitor widget)

## Phase 1: Skeleton & Config (független alap)
- [x] **1.1** `metadata.json` — plasmoid manifest (Plasma 6 API)
- [x] **1.2** `contents/config/main.xml` — KConfigXT séma (hiszterézis threshold-ok, színek, metrikák)
- [x] **1.3** `contents/ui/ConfigGeneral.qml` — KCM config UI (Kirigami, checkbox-ok, spinbox-ok)
- [x] **1.4** `CMakeLists.txt` — Build + `ki18n_install(po)`
- [ ] **1.5** Telepítés teszt: `kpackagetool6 --install` → megjelenik-e a widget listában?

## Phase 2: Data Layer (független, Phase 3-tól függ)
- [x] **2.1** `PlasmaCore.DataSource` integráció `main.qml`-ben — `systemmonitor` engine
- [x] **2.2** `StateEngine.qml` — metrika szűrés (enabledMetrics), hiszterézis, állapot számítás
- [x] **2.3** Error handling — DataSource `onError`, fallback üzenet
- [ ] **2.4** Teszt: `stress-ng` → state változik-e?

## Phase 3: UI Core (függ Phase 1-től és 2-től)
- [x] **3.1** `main.qml` — `PlasmoidItem` root, compact/full representation váltás
- [x] **3.2** `CompactView.qml` — panel ikon, SVG, tooltip (summary text)
- [x] **3.3** `ExpandedView.qml` — desktop widget, dragon + speech bubble
- [x] **3.4** `DragonCharacter.qml` — SVG megjelenítés, színváltás (state szerint)
- [x] **3.5** `SpeechBubble.qml` — megjelenés/elrejtés, anchors pozicionálás, animáció
- [ ] **3.6** Teszt: mindkét módban megjelenik, színek váltanak

## Phase 4: Animations (függ Phase 3-tól)
- [x] **4.1** Légzés animáció: `ScaleAnimator`, loop, state szerinti speed
- [x] **4.2** Pislogás: `Timer` + SVG layer váltás / opacity
- [x] **4.3** Farok mozgás: `RotationAnimator`, amplitúdó state szerint
- [ ] **4.4** Szárny mozgás (angry/critical): `RotationAnimator`
- [x] **4.5** Vibrálás (angry/critical): random offset `Timer`
- [x] **4.6** Állapotváltás smooth transition: `Behavior` on `scale`, `rotation`
- [ ] **4.7** Teszt: minden animáció látható, sebesség állítható configból

## Phase 5: Assets & Polish (függ Phase 3-tól)
- [x] **5.1** Dragon SVG: egy alap fájl, színezés `currentColor`-ral vagy `PlasmaCore.IconItem`-tel
- [x] **5.2** Szövegbuborék vizuális design: rounded rect, arrow, border
- [ ] **5.3** Panel ikon optimalizálás: skálázás 22px-64px között
- [ ] **5.4** Dark/light theme kompatibilitás

## Phase 6: Testing & Hardening (függ minden előzőtől)
- [ ] **6.1** Panel mode teszt: hozzáad, eltávolít, átméretez, újraindít
- [ ] **6.2** Desktop mode teszt: hozzáad, mozgat, resize, újraindít
- [ ] **6.3** Load teszt: stress-ng 1 perc, state váltások nyomon követése
- [ ] **6.4** Hiszterézis teszt: threshold határán nem villog
- [ ] **6.5** Config persistencia: beállít, újraindít, megmarad?
- [ ] **6.6** Error handling teszt: DataSource hiba → fallback üzenet
- [ ] **6.7** i18n teszt: magyar szövegek megjelennek

## Phase 7: Packaging & Delivery (függ Phase 6-tól)
- [ ] **7.1** `po/hu.po` — magyar fordítás
- [ ] **7.2** README.md: telepítési útmutató, screenshot helyek
- [ ] **7.3** Git repo: `asvanyviz/plasma-dragon-widget`
- [ ] **7.4** Tag: `v0.1.0`
- [ ] **7.5** GitHub Release

## Review Gates
- [x] **Plasma Advisor** — blueprint készítése
- [x] **Aporia Review** — blueprint review (⚠️ APPROVED WITH CHANGES)
- [x] **Blueprint javítások** — J1-J8 javítva
- [ ] **Mid-implementation review** — Phase 3 után
- [ ] **Final QA** — Phase 6 után: Zsolt jóváhagyás

## Függőségi gráf
```
0.1-0.3 ──► 1.1-1.5 ──► 2.1-2.4 ──► 3.1-3.6 ──► 4.1-4.7 ──► 5.1-5.4 ──► 6.1-6.7 ──► 7.1-7.5
                │           │            │            │            │            │
                └───────────┴────────────┴────────────┴────────────┴────────────┘
                                    (review gates)
```

## MVP kritikus útvonal (ha idő szűkös)
```
1.1 metadata.json → 1.2 main.xml → 2.1 DataSource → 2.2 StateEngine → 
3.1 main.qml → 3.2 CompactView → 3.3 ExpandedView → 3.4 DragonCharacter → 
3.5 SpeechBubble → 4.1 Légzés → 5.1 SVG → 6.1 Panel teszt → 6.3 Load teszt
```
