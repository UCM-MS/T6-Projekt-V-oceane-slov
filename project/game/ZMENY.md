# Zmeny: výprava za pokladom a minimapa (Veľká mapa)

Výprava za pokladom je vo „Veľkej mape (WIP)“. Minimapa je v oboch režimoch, aj v klasickom „Vstúpiť do vody“.

## Čo pribudlo v hre

**Výprava za pokladom (viackrokový encounter)**
1. Na mape sa objaví potopený vrak (pulzuje a na minimape je hnedá značka).
2. Pri vraku sa otvorí úloha „Kapitánov denník“: 3 vety, treba aspoň 2 správne.
3. Po splnení sa ukáže truhla (väčšinou v jaskyni) a na minimape sa objaví zlatá značka.
4. Pri truhle sa otvorí úloha „Zámok truhly“: 3 vety, všetky musia byť správne.
5. Odmena: truhla sa otvorí, hráč dostane perlu a 5 bonusových bodov (v hornom riadku pribudne „Perly: 1“).
- Ak úlohu nesplní, môže to skúsiť znova, keď odpláva kúsok preč a vráti sa.
- Otázky sa berú zo slovníka podľa nastavení (spoluhlásky). V jednej úlohe sa slovo neopakuje. Chybné slová sa precvičujú ako pri zvieratkách.
- Vľavo hore je riadok s aktuálnym cieľom výpravy.

**Minimapa** (vpravo dole, v oboch mapách)
- Celý profil dna vrátane jaskýň, hladina, bodka žraloka a rámik práve viditeľnej časti mapy.
- Vo Veľkej mape aj značky vraku a truhly.
- Minimapa je v spoločnej scéne `dive.tscn`. Každá mapa jej pri štarte odovzdá hranice sveta a polygóny dna a jaskýň (`minimap.setup(...)`).

**Preddefinované miesta spawnu v dlaždiciach**
- Dlaždice v `map_tiles/` majú `Marker2D` body v skupinách:
  - `spawn_wreck`: rovné dno pre vrak (basin, spodok útesu a strmého svahu),
  - `spawn_chest`: miesta v jaskyniach (tunel, odbočka tunela, slepý koniec),
  - `spawn_chest_alt`: záložné miesta mimo jaskýň (medzi riasami, na útese, na šelfe).
- Generátor ich zozbiera z položených dlaždíc (aj zo zrkadlovo otočených) a vyberie miesto pre vrak a truhlu (truhla aspoň 3 dlaždice od vraku, prednostne v jaskyni).
- Nové miesto pridáš tak, že do dlaždice v editore vložíš `Marker2D` a dáš ho do jednej z týchto skupín.

## Súbory

Nové:
- `treasure_quest.gd`: logika výpravy (stavy, texty úloh, odmena)
- `quest_site.gd`: spoločný skript vraku a truhly (pulzovanie, otvorenie, zrkadlenie)
- `wreck.tscn`: vrak (kresba prevzatá z `dive_regions.tscn`)
- `chest.tscn`: truhla (zatvorená aj otvorená)
- `minimap.gd`: minimapa (nezávislá od typu mapy)

Upravené:
- `water.gd`: kvíz vie položiť viac otázok za sebou ako jednu úlohu, počítanie bonusových bodov a perál
- `large_map.gd`: zber miest spawnu z dlaždíc a výber miesta pre vrak a truhlu
- `large_dive.gd`, `large_dive.tscn`: spustenie výpravy, nastavenie minimapy, riadok s cieľom
- `dive.tscn`: pridaný uzol minimapy do HUD (zdieľajú ho obe mapy)
- `test_dive.gd`: nastavenie minimapy pre klasickú mapu
- `map_tiles/*.tscn`: pridané body spawnu

## Testovanie
Hra bola spustená v Godot 4.7. Automatický test prešiel celú výpravu (zlyhanie, opakovanie, vrak, truhla, odmena) na 150 náhodne vygenerovaných mapách bez chyby.

## Na dohodnutie
- Je výprava jedna na mapu, alebo sa má po otvorení truhly spustiť ďalšia?
- Akú odmenu chceme (perla a body sú zatiaľ provizórne)?
- Obťažnosť úloh: počet viet a koľko musí byť správne je v `treasure_quest.gd` v `CHALLENGES`.
