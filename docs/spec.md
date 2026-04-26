# Plasma Dragon System Monitor Widget — Specifikáció

## Cél
Egy KDE Plasma plasmoid, amely egy sárkány karaktert jelenít meg a rendszer terheltségének állapotától függően. Inspiráció: catwalk widget, de fejlettebb kinézetben és funkcionalitásban.

## Elhelyezkedési módok
1. **Panel mód:** Kompakt nézet. A sárkány ikonja / mini-ábrázolása színváltozással jelzi a terheltséget.
2. **Asztal mód (desktop widget):** Nagyobb, részletesebb nézet. A sárkány animált. Szövegbuborék jelenik meg, amely konkrétan leírja, milyen jellegű terheltségnél érez problémát (pl. "CPU túlterhelt: 85%", "RAM kevés: 90% foglalt").

## Megjelenítendő metrikák
- CPU használat (%)
- RAM használat (%)
- Disk I/O (opcionális)
- CPU/GPU hőmérséklet (opcionális)
- Hálózati terhelés (opcionális)
A widget konfigurálható legyen, hogy mely metrikákat figyelje.

## Sárkány állapotok (terhelés szerint)
- **Nyugodt** (alacsony terhelés, <40%): nyugodt színek, lassú légzés animáció
- **Éber** (közepes terhelés, 40-70%): éberebb testtartás, élénkebb színek
- **Haragos** (magas terhelés, 70-90%): agresszív testtartás, vibrálás / tűz effekt
- **Kritikus / Vörös** (extrém terhelés, >90%): vörös izzás, erőteljes figyelmeztetés

## Szövegbuborék (asztal mód)
- Csak asztali módban jelenik meg
- Konkrét, érthető szöveget tartalmaz a problémás metrikáról
- Automatikusan eltűnik, ha a terhelés normalizálódik
- Pozíció: a sárkány mellett, dinamikusan igazodik

## Kinézet
- Sárkány stílus: catwalk-nál fejlettebb, részletesebb
- Skálázható méret (panel: 22-64px, asztal: 128px+)
- Animációk: légzés, pislogás, farokmozgás, szárny mozgás (állapot függő)
- Színpaletta: konfigurálható, de alapból zöld → sárga → narancs → vörös skála

## Konfigurációs lehetőségek
- Mely metrikák legyenek figyelve (checkbox lista)
- Küszöbértékek állapotonként (slider-ekkel)
- Színek testreszabása állapotonként
- Animáció sebesség
- Szövegbuborék ki/be (asztal mód)

## Technológia
- KDE Plasma 6 kompatibilis (Plasma 5 visszafelé kompatibilitás kívánatos, de nem kötelező)
- QML + JavaScript
- C++ backend a rendszerstatisztikákhoz (plasma dataengine vagy saját C++ plugin)
- Szabványos Plasma plasmoid struktúra (metadata.json, main.qml, etc.)

## Forgatókönyvek
1. User hozzáadja a widgetet a panelhoz → kompakt sárkány ikon, szín változik a terhelés szerint
2. User hozzáadja az asztalhoz → nagyobb sárkány, szövegbuborékban figyelmeztetés
3. Terhelés emelkedik → sárkány átmenet az állapotok között, szövegbuborék frissül
4. Terhelés normalizálódik → vissza nyugodt állapotba, buborék eltűnik
