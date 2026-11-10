# V oceáne slov

**V oceáne slov** je 2D vzdelávacia hra v Godote, v ktorej hráč ako žralok objavuje podmorský svet a precvičuje si písanie **i, í, y, ý** po obojakých spoluhláskach.

## Čo hra ponúka

- **Voľné plávanie** po testovacej mape s plytčinou, členitým dnom, vrakom lode a skalnou norou, do ktorej sa dá vplávať. Žralok môže vyskočiť nad hladinu a pri dopade spraví šplech.
- **Sedem morských tvorov** s rôznym pohybom. Ryby plávajú po zakrivených dráhach, kraby chodia po dne a medúzy sa vznášajú hore a dole.
- **Pravopisné otázky** sa otvoria, keď žralok dopláva k tvorovi. Po odpovedi hra ukáže správny tvar a vysvetlenie. Po stlačení tlačidla na pokračovanie žralok pri správnej odpovedi tvora zhltne a pri nesprávnej tvor utečie. Potom sa objaví na inom mieste.
- **Slovník s 289 položkami v JSON-e.** Obsahuje vybrané a príbuzné slová aj slová s mäkkým `i` alebo `í`. Pri dvojiciach ako *byť* a *biť* pomáha významová nápoveda.
- **Výber skupín v nastaveniach.** Hráč si môže zapnúť skupiny **b, m, p, r, s, v, z**. Výber sa uloží aj po vypnutí hry.
- **Opakovanie slov, v ktorých hráč chybuje.** Hra ich počas spustenia ponúka častejšie, kým hráč dané slovo dvakrát správne nezodpovie bez ďalšej chyby v ňom.

Ponor nemá časový limit ani povinný počet otázok. Hra priebežne zobrazuje počet odpovedí a skóre. Hráč môže kedykoľvek pokračovať v objavovaní alebo sa vrátiť do hlavného menu.

## Ovládanie

| Akcia | Ovládanie |
|---|---|
| Plávanie | `WASD`, šípky alebo myš |
| Nastavenie cieľa | Krátke kliknutie ľavým tlačidlom |
| Sledovanie kurzora | Podržanie ľavého tlačidla |
| Výskok | Rozplávaj sa smerom k hladine klávesnicou alebo nasmeruj žraloka myšou nad hladinu |
| Odpoveď | Kláves `i`, `í`, `y`, `ý` alebo kliknutie na možnosť |
| Návrat do menu | `Esc` alebo tlačidlo **Späť do menu** |

## Spustenie

V **Godote 4.7** importuj projekt cez `project/game/project.godot` a spusti ho klávesom `F5`.
