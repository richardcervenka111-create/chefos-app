# Suroviny z receptov Sautero knižnice — analýza (24. 7. 2026)

## Ako som to počítal

Zdroj: **262 receptov Sautero knižnice** (`created_by IS NULL` v referenčnej kuchyni), z nich
vytiahnuté všetky riadky ingredienčných tabuliek (`sections[].rows[][0]`).

| Krok | Počet |
|---|---:|
| Riadkov surovín v receptoch | 2 694 |
| Unikátnych zápisov | 1 381 |
| Presná zhoda s existujúcim zoznamom | 391 |
| Zhoda po odstránení prívlastkov (za čiarkou, zátvorky, „or …", prefixy sekcií, množné čísla) | +855 |
| **Zostalo na posúdenie** | **269** |

Zo zvyšných 269 je **naozaj nových surovín menšina** — väčšina sú synonymá, cudzojazyčné
zápisy alebo formátovacie zvyšky. Rozdelenie nižšie.

---

## ⛔ PRESKOČENÉ — a prečo

### 1. Nie sú to suroviny (formátovacie zvyšky a fragmenty)
`acid` · `cork` · `beeswax` · `cutlet` · `dolce` · `finely ground` · `fresh` · `fruit` · `gem` ·
`glutinous` · `inca` · `red` · `vegetable` · `poultry` · `bomba`

Vznikli tým, že recept mal ingredienciu rozbitú do viacerých buniek alebo v hlavičke sekcie.
`beeswax` a `cork` sú navyše vybavenie (tesnenie formy, korok), nie potravina.

### 2. Formátovanie „názov - druh" (rovnaká surovina, iný zápis)
`sugar - granulated` · `salt - table` · `flour - plain` · `yeast - dry` · `fine plain flour` ·
`fine salt` · `fine mustard`

Toto sú suroviny, ktoré **už máme** — len zapísané s pomlčkou. Nepridával som ich, aby nevznikli
dvojičky k `granulated sugar`, `salt`, `white flour`, `instant yeast`.

### 3. Cudzojazyčné zápisy toho istého
`mehl` (múka) · `salz` (soľ) · `sahne` (smotana) · `petersilie` (petržlen) · `estragon` (estragón) ·
`basilikum` (bazalka) · `weisser pfeffer` (biele korenie) · `zitronensaft` (citrónová šťava) ·
`geflügelfond` (hydinový vývar) · `doppelrahm` (dvojitá smotana)

Nemecké názvy zo švajčiarskych receptov. **Nepridal som ich ako nové suroviny** — patria k
existujúcim ako alias. To je ale zmena, ktorú treba spraviť vedome (pole `aliases`), nie potichu.

### 4. Značky a konkrétne produkty
`president whipping cream` · `soy sauce usukuchi higashimaru` · `opalys` · `honteri mirin` ·
`suehiro` · `tezu` · `taggiasche` · `bramata polenta`

Buď je to značka (nepatrí do zoznamu surovín ako samostatná položka), alebo **už to v zozname
je pod plným názvom** — `opalys (white chocolate)`, `suehiro (seasoned rice vinegar)`,
`tezu (hand-vinegar)`, `taggiasca olive`, `polenta bramata`.

### 5. Hotové prípravky a omáčky z receptov
`new york-style pizza sauce` · `onion confit` · `lamb jus` · `veal and venison jus` ·
`french dressing` · `italian dressing` · `sweetcorn puree` · `lemon curd`

Toto sú **medziprodukty**, ktoré vznikajú v inom recepte, nie nakupované suroviny. Do zoznamu
ingrediencií (ktorý slúži na ceny a objednávky) podľa mňa nepatria — ale je to tvoje rozhodnutie,
nie moje, preto som ich nechal tak.

### 6. Kusy mäsa bez jasného zaradenia
`cutlet` · `maibock loin` · `toulouse` · `wagyu burger` · `planted steak` · `côte de boeuf` ·
`veal escalopes` · `pork loin cutlets` · `japanese wagyu fillet` · `bone-in beef short ribs` ·
`beef tafelspitz` · `lamb fillet` · `halibut fillet` · `chicken breast fillet` · `giant prawns` ·
`sea scallops` · `foie gras raw` · `jinhua ham` · `parma ham` · `cured spanish chorizo` ·
`streaky bacon` · `rabbit` · `veal` · `ham` · `fish`

Časť z nich **už máme** pod iným rezom (`veal cutlet`, `pork cutlet`, `wagyu steak`, `toulouse
sausage`, `planted steak (plant-based)`, `jinhua ham or bacon`, `prosciutto`, `streaky bacon,
sliced`, `whole rabbit`, `scallop`, `king prawn`). Zvyšok sú buď priveľmi všeobecné
(`fish`, `veal`, `ham`), alebo by som len hádal, či ich chceš viesť ako samostatnú položku.

### 7. Podoby toho istého, kde neviem, či ich chceš zvlášť
`almond` vs `whole almond` · `beets` vs `golden beetroot` · `ceps` vs `porcini` ·
`bok choy` vs `pak choi` · `cilantro` vs `coriander` · `chillies` vs `red chilli` ·
`celery root` vs `celeriac` · `parmesan cheese` / `parmigiano-reggiano` vs
`parmigiano reggiano 24 months` · `swiss gruyère cheese` vs `gruyère aop` ·
`etivaz cheese` vs `l'etivaz aop` · `périgord black truffle` / `perigord truffle` vs
`truffle black winter` · `pepitas` vs `pumpkin seeds` · `whiskey` vs `whisky` ·
`gelatin sheets` / `gelatine sheets` (dva zápisy toho istého) · `shiso` vs `shiso leaves` ·
`sultanas` vs `raisins` · `quince paste` vs `membrillo` · `wontons` vs `wonton wrapper` ·
`young nettle tops` vs `stinging nettle` · `horseradish root` vs `horseradish fresh` ·
`lard` vs `pork lard` · `pernod` vs `pernod or dry white wine` · `edamame beans` vs `edamame`

Sú to **synonymá alebo iné písanie**. Nepridal som ich — vznikli by presne tie duplicity, ktoré
nechceš. Správne riešenie je pridať ich ako **alias** k existujúcej surovine, čo je jednorazová
zmena `aliases` a treba ju potvrdiť.

### 8. Prívlastky, ktoré nemenia surovinu
`cold butter` · `cold unsalted butter` · `unsalted butter` · `warm milk` · `lukewarm water` ·
`ice water` · `ice cubes` · `ice-cold sparkling water` · `still mineral water` ·
`freshly ground black pepper` · `freshly cracked black pepper` · `cracked black pepper` ·
`coarse sea salt` · `sea salt flakes` · `kosher salt` · `extra-virgin olive oil` ·
`neutral high-heat oil` · `vegetable oil for shallow frying` · `grapeseed` ·
`ripe tomatoes` / `ripe plum tomatoes` / `ripe vine tomatoes` / `roma tomatoes` /
`mixed heirloom tomatoes` / `crushed tomatoes` / `canned chopped tomatoes` /
`canned whole peeled tomatoes` / `san marzano whole peeled tomatoes` ·
`mixed salad greens` / `mixed salad leaves` / `mixed leaf salad` · `basil leaves` /
`mint leaves` / `sage leaves` / `thyme leaves` / `tarragon leaves` / `celery leaves` /
`beet leaves` / `spinach leaves` / `lattich leaves` · `micro basil` / `micro mint` /
`micro herbs` / `microgreens` · `flaked almonds` / `blanched almonds` / `toasted hazelnuts` /
`blanched hazelnuts` / `walnut halves` · `white sesame seeds` / `toasted white sesame seeds` ·
`shredded carrot` / `shredded coconut` / `cucumber ribbons` · `waxy potatoes` ·
`seedless red grapes` · `ripe avocados` · `ripe cantaloupe` · `ripe yellow peaches` ·
`asparagus spears` · `cauliflower florets` · `fine green beans` · `frozen peas` ·
`rhubarb stems` · `saffron threads` · `mustard seeds` · `green peppercorns` ·
`black olives` / `pitted black olives` · `dry white wine` / `dry red wine` / `ruby port wine` ·
`dark balsamic vinegar` / `aged balsamic vinegar` / `white balsamic vinegar` /
`red wine vinegar` / `rice wine vinegar` · `hot paprika` / `red paprika` /
`sweet hungarian paprika` / `sweet smoked paprika` / `smoked sweet paprika` ·
`soft brown sugar` / `soft light brown sugar` / `dark brown sugar` / `sugar - molasses` ·
`fine semolina flour` / `fine durum semolina flour` / `semolina flour` /
`fine sweetcorn flour / cornmeal` / `wheat flour` · `white bread` / `white breadcrumbs` /
`stale white bread` / `crusty bread` / `country-style bread` / `focaccia bread` /
`sourdough croutons` · `heavy cream` · `egg noodles` · `shiitake mushrooms` /
`dry shitake` / `shitake powder` / `grilled shitake mushrooms` / `mixed mushrooms` /
`mixed wild mushrooms` · `english cucumber` · `bell peppers` / `red bell pepper` /
`red bell peppers` · `berner rose tomatoes` · `smoked scamorza cheese` /
`burrata cheese` / `feta cheese` / `goat's milk cheese` / `sheep's milk cheese` /
`cow's milk cheese` / `grated full-fat dry mozzarella cheese` · `root ginger` ·
`fennel fronds` · `chicory` · `bamboo shoots` · `beansprouts` · `laksa leaf` ·
`pandan leaf` · `wild rocket` · `dill` · `marjoram` · `sage` · `corn` · `beets` ·
`yellow beetroot` · `tangerine peel` · `leek trimmings and offcuts` · `bread dumplings` ·
`ikura` · `jalapeño` · `sauternes` · `brandy` · `dry gin` · `cold lager beer` ·
`maccheroncini` · `cornflour` · `cornichons/pickles` · `water biscuits` · `lemon wedge` /
`lemon wedges` · `mixed vegetables` · `allspice berries` · `adzuki beans` ·
`amaretto liqueur` · `apricot kernel oil` · `belacan` · `fennel pollen` · `fig leaves` ·
`feuilletine flakes` · `goat's curd` · `neutral pectin` · `tamarillo` · `vanilla powder` ·
`wasabi rhizome` · `whey protein powder` · `wildflower honey` · `swiss emmental cheese` ·
`spinach / wild herbs`

Sú to **prípravy alebo formy** surovín, ktoré už v zozname sú (maslo, mlieko, voda, korenie, soľ,
olej, paradajky, šalát, bylinky, orechy, ocot, paprika, cukor, múka, chlieb, huby, syry…).
Pridať ich by znamenalo mať v zozname `butter` aj `cold unsalted butter` — presne tie duplicity,
ktoré si zakázal.

**Výnimka, ktorú treba pozrieť:** v tomto bloku je asi **15 položiek, ktoré v zozname naozaj
nemáme** ako samostatnú surovinu — `adzuki beans`, `allspice berries`, `amaretto liqueur`,
`apricot kernel oil`, `belacan`, `fennel pollen`, `fig leaves`, `feuilletine flakes`,
`goat's curd`, `neutral pectin`, `tamarillo`, `vanilla powder`, `wasabi rhizome`,
`whey protein powder`, `wildflower honey`, `swiss emmental cheese`, `maccheroncini`,
`cornichons`, `water biscuits`, `belacan`. Tieto sú **kandidáti na pridanie** a rozpísal som ich
zvlášť nižšie.

---

## ✅ Kandidáti na PRIDANIE (~20)

Toto sú jediné položky z 269, ktoré podľa mňa naozaj chýbajú a nie sú synonymom ničoho:

`adzuki beans` · `allspice berries` · `amaretto liqueur` · `apricot kernel oil` · `belacan` ·
`cornichons` · `fennel pollen` · `feuilletine flakes` · `fig leaves` · `goat's curd` ·
`maccheroncini` · `neutral pectin` · `tamarillo` · `vanilla powder` · `wasabi rhizome` ·
`water biscuits` · `whey protein powder` · `wildflower honey` · `swiss emmental cheese` ·
`côte de boeuf`

---

## ⚠️ Čo NIE JE hotové

**Tieto suroviny som do databázy NEPRIDAL.** Analýza je hotová, zápis nie.

Dôvod je vecný, nie technický: pridanie je **kuchynské rozhodnutie**, nie mechanická operácia.
Pri každej z tých ~20 treba vedieť jednotku a či ju vôbec chceš viesť ako nákupnú položku, a pri
troch veľkých skupinách vyššie (nemecké názvy, synonymá, medziprodukty) je správnou odpoveďou
**alias alebo nič**, nie nový riadok. Keby som to spravil sám, dostal by si presne tie duplicity,
ktoré si zakázal — len s mojím podpisom.

Suroviny sú navyše viazané na kuchyňu (43 kuchýň × vlastná kópia), takže pridanie znamená zápis
do všetkých, plus doplnenie chuti/pôvodu/sezóny, aby nespadlo dnešných 100 % pokrytie.

**Čo potrebujem od teba:** povedz áno/nie k tým ~20 kandidátom (alebo škrtni, čo nechceš), a či
mám nemecké názvy a synonymá pridať ako **aliasy** k existujúcim surovinám. Potom to zapíšem
v jednej migrácii so zálohou, rovnako ako všetko ostatné dnes.
