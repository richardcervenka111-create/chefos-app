# Sautero de-CH Glossary (locked)

Canonical terms. The "Never use" column lists translations that are grammatically
correct but wrong for a Swiss professional kitchen — either too literal, too German
(DE-DE), or ambiguous on the pass.

If a term is missing, add it here in the same change and flag it to the user.
Never silently invent a synonym.

## Core kitchen

| EN | de-CH | Plural | Never use |
|---|---|---|---|
| Recipe | das Rezept | Rezepte | Kochanleitung |
| Recipe book | das Rezeptbuch | Rezeptbücher | Kochbuch |
| Ingredient | die Zutat | Zutaten | Bestandteil, Ingredienz |
| Prep / mise en place | Mise en Place | — | Vorbereitung (as UI label) |
| Prep list | die Rüstliste | Rüstlisten | Vorbereitungsliste |
| Prep board | das Rüstboard | — | Vorbereitungstafel |
| Yield / portions | die Portionen | — | Ausbeute (only in food cost context) |
| Portion size | die Portionsgrösse | — | Portionsgröße (ß!) |
| Batch | die Charge | Chargen | Stapel, Produktionsstapel |
| Station | der Posten | Posten | Station (ambiguous) |
| Service | der Service | — | Dienst |
| Shift | die Schicht | Schichten | Dienst |
| Chef de partie | Chef de Partie | — | Postenchef (unless user prefers) |
| Head chef | der Küchenchef | Küchenchefs | Chefkoch |
| Kitchen staff | das Küchenteam | — | Küchenpersonal (dated) |
| Supplier | der Lieferant | Lieferanten | Zulieferer |
| Delivery | die Lieferung | Lieferungen | Anlieferung |
| Order | die Bestellung | Bestellungen | Order, Auftrag |
| Stock / inventory | der Warenbestand | — | Inventar (means the count event) |
| Stocktake | die Inventur | Inventuren | Bestandsaufnahme |
| Waste | der Abfall | — | Müll, Verlust |
| Unit | die Einheit | Einheiten | Masseinheit (unless explicit) |
| Net weight | das Nettogewicht | — | — |
| Shelf life | die Haltbarkeit | — | Lagerfähigkeit |
| Best before | mindestens haltbar bis | — | Ablaufdatum |
| Use by | zu verbrauchen bis | — | Verfallsdatum |

## Food cost

| EN | de-CH | Never use |
|---|---|---|
| Food cost | die Foodcost | Lebensmittelkosten (in UI) |
| Cost price | der Einstandspreis | Kostpreis |
| Selling price | der Verkaufspreis | — |
| Margin | die Marge | Gewinnspanne |
| Gross profit | der Bruttogewinn | Rohertrag |
| Price per unit | der Einheitspreis | Stückpreis (only for countables) |
| Estimated price | geschätzter Preis | — |
| Verified price | verifizierter Preis | bestätigter Preis |
| VAT | die MWST | MwSt. (DE spelling) |

## HACCP / hygiene (legally sensitive — do not paraphrase)

| EN | de-CH | Never use |
|---|---|---|
| HACCP | HACCP | — |
| Self-monitoring concept | das Selbstkontrollkonzept | Eigenkontrolle |
| Traceability | die Rückverfolgbarkeit | Nachverfolgung |
| Critical control point | der kritische Kontrollpunkt (CCP) | — |
| Temperature log | die Temperaturkontrolle | Temperaturprotokoll (ok in exports) |
| Core temperature | die Kerntemperatur | Innentemperatur |
| Cooling chain | die Kühlkette | Kältekette |
| Blast chiller | der Schnellkühler | Schockfroster (that's a freezer) |
| Cross-contamination | die Kreuzkontamination | Verunreinigung |
| Allergen | das Allergen | Allergiestoff |
| Declaration | die Deklaration | Kennzeichnung (broader term) |
| Label | die Etikette | das Label, der Aufkleber |
| Print label | Etikette drucken | Label drucken |
| Corrective action | die Korrekturmassnahme | Gegenmassnahme |
| Audit / inspection | die Kontrolle | Inspektion, Audit |

Note: Swiss usage is **die Etikette** (not das Etikett). Keep it consistent everywhere.

## Time tracking

| EN | de-CH | Never use |
|---|---|---|
| Working time | die Arbeitszeit | Dienstzeit |
| Clock in | Einstempeln | Anmelden |
| Clock out | Ausstempeln | Abmelden |
| Break | die Pause | Unterbruch |
| Overtime | die Überstunden | Mehrarbeit |
| Roster / schedule | der Einsatzplan | Dienstplan (DE), Schichtplan |
| Absence | die Absenz | Abwesenheit |
| Holiday / vacation | die Ferien | der Urlaub (that's leave in DE) |

## App chrome

| EN | de-CH | Never use |
|---|---|---|
| Save | Speichern | Sichern, Übernehmen |
| Cancel | Abbrechen | Zurück |
| Delete | Löschen | Entfernen (use for list removal only) |
| Remove (from list) | Entfernen | Löschen |
| Add | Hinzufügen | Erfassen (use for new records) |
| Create new | Neu erfassen | Anlegen |
| Edit | Bearbeiten | Ändern |
| Duplicate | Duplizieren | Kopieren |
| Search | Suchen | — |
| Filter | Filtern | — |
| Export | Exportieren | — |
| Settings | Einstellungen | Konfiguration |
| Dashboard | die Übersicht | Dashboard, Armaturenbrett |
| Loading… | Wird geladen… | Lädt… |
| No entries yet | Noch keine Einträge | Keine Daten vorhanden |
| Required field | Pflichtfeld | Erforderliches Feld |
| Changes saved | Änderungen gespeichert | Erfolgreich gespeichert! |

## Style notes

- Nouns capitalised, obviously — but check generated/interpolated strings too.
- Buttons: bare infinitive (`Speichern`), no article, no full stop.
- Messages: full sentence, full stop, no exclamation mark.
- Tooltips: no full stop if a fragment.
- Anglicisms are fine where the trade uses them (`Foodcost`, `Mise en Place`, `Service`,
  `HACCP`). Do not "purify" them into invented German compounds.
- French loanwords keep their accents: `Mise en Place`, `Sauté`, `Purée`.
