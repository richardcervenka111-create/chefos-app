
## 🩺 Deep health check — 17. 7. 2026, 18:39 (na Richardovu žiadosť)

**Databáza (naživo, produkcia):** 46 tabuliek, **0 bez RLS**, 157 politík, **0 verejných
storage bucketov**, všetky SECURITY DEFINER funkcie s pripnutým search_path, **0 chýb
v error_logs za 24 h**. Dáta: 12 profilov (0 bez kuchyne), 20 kuchýň, 183 knižničných
receptov (0 neobohatených po Michelin passe), 2 005 položiek ChefOS cenníka, 6 komentárov,
ai_usage 8 riadkov (meranie per užívateľ reálne zapisuje), recipe_shares 1 (per-friend
zdieľanie po db/144 potvrdene funguje).

**Auditory:** audit_db aj audit_app čisté (144 migrácií). Merač hodín: 47,1 h presne z gitu
+ ~40 h odhad = **~87,1 h** (17.7. = 5,6 h) — prenesené do tasklist/costs/status.

**NÁLEZ → OPRAVENÉ:** edge funkcia **notify-access-request nebola nasadená** (v cloude bežal
len claude-proxy v8) — appka ju volá fire-and-forget, takže emailové upozornenia na nové
žiadosti o prístup ticho zlyhávali. Nasadená počas kontroly. Trieda tichých zlyhaní —
kandidát na trvalú poistku: kontrola zoznamu nasadených funkcií proti supabase/functions/
v auditoroch.

**Otvorené (vedome):** ai_unlimited_testing_mode = ON (vypnúť pred trialom — backlog t166);
coming_soon = ON (zámer do trialu); 1 aktívna pozvánka na hlavnú kuchyňu (overiť s Richardom
— ak nie je jeho dnešná, odvolať); RLS test receptov „Moje" z 2 účtov ešte čaká (ingrediencie
už potvrdené testom „Tajná marináda").

## 🩺 Deep health check v2 — 18. 7. 2026, ráno (opravený dátum — kontrola bežala po polnoci) (po nasadení redesignu)

**Stav:** auditory čisté (144 migrácií, 48 tabuliek), obe edge funkcie ACTIVE (claude-proxy v8,
notify-access-request v1), **0 chýb v error_logs za 3 h po nasadení novej témy**, ai_usage 9
riadkov, recipe_shares 1, 13 profilov. Klasická téma na produkcii nezmenená; theme-new kód
neaktívny pre všetkých okrem zakladateľovho prepínača. Hodiny: 47,9 h git + ~40 h = **~87,9 h**.

**NÁLEZ 1 → OPRAVENÉ (dáta + kód):** nový užívateľ **Adam Bazik** (adambazik1991@gmail.com,
registrácia dnes večer) uviazol bez kuchyne — schválený užívateľ bez pozvánkového kontextu
nemal v bráne ŽIADNU cestu ku kuchyni (rovnaká trieda ako patrik/anny/sergey z db/140).
Jednorazovo: vytvorená Adam's Kitchen a priradená. Trvalo: renderTeamGate() teraz schválenému
užívateľovi bez pozvánky automaticky založí vlastnú kuchyňu (ensure_personal_kitchen, db/110)
namiesto slepej hlášky.

**NÁLEZ 2 → OPRAVENÉ (nová téma):** tri komponenty používajú --rule ako plné pozadie
(wt-dot/bar-absence, fridge-status-dot.none) — po premapovaní premenných na 9% hairline by boli
v Novej téme takmer neviditeľné; dostali pevnú vrstvu nv-3. (.sheet-handle bol pokrytý už
v celku 2.)
