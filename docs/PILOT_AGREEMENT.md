# Sautero — Pilot Program Agreement / Pilotprogramm-Vereinbarung

*Draft v2 — 2026-07-17. Dvojjazyčná verzia (angličtina + nemčina) pripravená na kontrolu
právnikom — NIE JE finálna a neprešla právnym posúdením. Oproti v1 (13.7.) doplnená podľa
skutočného stavu appky: GPS snímka pri dochádzke, menovité hodiny len so súhlasom zamestnanca,
oddelenie osobných a firemných dát, heslo + in-app súhlasy, centrálny AI kľúč, dobrovoľné
zdieľanie receptov s Sautero. Otázky pre právnika sú na konci. Anglická a nemecká verzia majú
zhodné číslovanie, aby sa dali kontrolovať vedľa seba.*

---

## ENGLISH VERSION

**Between:** __________________________ ("the Kitchen")
**And:** Richard Červenka, Sautero ("the Developer")
**Venue(s) covered:** __________________________
**Start date:** __________________________

### 1. What Sautero is

Sautero is a **beta (pre-release) kitchen-management application**, under active daily
development. Features can change, break, or be removed without notice during the pilot. It is
not a finished, commercially supported product yet, and no particular availability, feature,
or support level is promised.

### 2. Accounts and access

- Access is **invite-only**. Each team member gets their own account (email + password;
  optionally a device-local Face ID/fingerprint unlock — biometric data never leaves the
  device).
- Before first use, every team member accepts a confidentiality notice and a privacy notice
  inside the app. The Kitchen will make sure its staff know that using Sautero is part of the
  pilot.
- Two account modes exist: **Company** (the Kitchen's shared workspace) and **Personal**
  (an individual's private notebook). Anything saved as Personal is private to that individual
  at the database level — the Kitchen and its admins cannot read it, and it is **not** covered
  by section 3's "belongs to the Kitchen" rule.

### 3. Data

- Everything entered into the Kitchen's shared workspace — recipes, prep lists, ingredient
  prices, orders, printed-label logs, HACCP records, schedules, working-time logs, photos —
  **belongs to the Kitchen**.
- Data is stored with Supabase, a third-party managed database provider. The Developer does
  not sell or share the Kitchen's data and uses it for no purpose other than running the app.
- **Working time is genuine employee data** and is treated with extra care:
  - Check-in/check-out times, breaks and day notes are visible to the team member they belong
    to. A kitchen admin sees the team's hours **only as an anonymous total**, unless a team
    member individually opts in (in their own settings, revocable at any time) to show their
    name next to their hours.
  - At the moment of check-in and check-out the app records a **one-time GPS location
    snapshot** (no continuous tracking, ever). It is visible to the team member in their own
    day view and is used for no other purpose.
- The app keeps basic technical logs (logins, which screens get opened, JavaScript errors) to
  see whether the pilot is used and to fix bugs; these are visible only to the Developer. Email
  addresses that reach Sautero (access requests, invites) are kept in an internal contact log.
- The Kitchen can request an export of its data, or its deletion, at any time (see section 8).

### 4. AI features

- Some features (photo/PDF/Excel scanning of recipes, menus, price lists, schedules or
  contracts; recipe generation; field suggestions; the Chef's Assistant chat) send the
  relevant text or image to **Anthropic's Claude API** for processing, via Sautero's own server
  and Sautero's own API key. No data is used to train AI models beyond what Anthropic's
  standard API terms cover.
- During the pilot, AI features are included **at no cost** to the Kitchen, within fair use.
- When saving a recipe, the app may ask whether the author wants to **contribute it to the
  shared Sautero library**. This is voluntary and per-recipe. Contributed recipes may be
  reviewed by the Developer and, if accepted, included in the library available to other
  Sautero kitchens. A contribution can be withdrawn on request; copies already distributed to
  other kitchens' shelves may remain there.
- AI output (suggested dates, quantities, texts, translations) can be wrong. A professional
  reviews before relying on it — see section 5.

### 5. Food-safety (HACCP) disclaimer

Sautero can suggest shelf-life "use by" dates, generate food-safety labels, and store HACCP
records (temperatures, cleaning checklists, oil changes, pest checks) based on information
entered into the app. **These are tools to assist the Kitchen's own food-safety process — they
are not a substitute for the Kitchen's own HACCP procedures, training, or professional
judgment.** The Kitchen remains solely responsible for verifying any date, label, temperature
or record before relying on it. The Developer accepts no liability for food-safety outcomes
arising from use of the app during the pilot.

### 6. No cost, no obligation

Participation in the pilot is **free and voluntary**. The Kitchen does not commit to becoming
a paying customer; the Developer does not commit to any feature, timeline, or support level.
Any future paid offer (e.g. a founding-member subscription) will be a separate, optional
agreement.

### 7. Availability and liability

Sautero is provided **"as is"**, without warranty. The Developer makes reasonable efforts to
keep the app running and the data safe (managed hosting, provider backups, access controls),
but does not guarantee availability or freedom from errors. To the extent permitted by Swiss
law, the Developer's liability under this pilot is excluded; mandatory liability (unlawful
intent, gross negligence) remains unaffected.

### 8. Term and ending the pilot

Either party may end the pilot **at any time, for any reason, with no penalty**. On request,
the Kitchen's data will be exported in a common format and/or deleted within 30 days.
Sections 5 and 7 survive the end of the pilot.

### 9. Data-protection roles

For its team's personal data processed in Sautero, the Kitchen acts as the responsible party
(controller) and the Developer processes that data on the Kitchen's behalf for the purpose of
running the app (Swiss nDSG; GDPR where applicable). Details of this split are one of the
points to be confirmed by legal review (see the questions at the end).

### 10. Governing law and languages

This agreement is governed by **Swiss law**; place of jurisdiction is Bern (to be confirmed).
It is signed in English and German versions with identical numbering. In case of discrepancy,
the **German version prevails**.

### 11. Contact

Questions or issues during the pilot: __________________________ (Richard's contact info)

**Signed:**

Kitchen representative: _________________________ Date: _____________

Richard Červenka (Sautero): _________________________ Date: _____________

---

## DEUTSCHE VERSION

**Zwischen:** __________________________ («die Küche»)
**Und:** Richard Červenka, Sautero («der Entwickler»)
**Betroffene Betriebe:** __________________________
**Startdatum:** __________________________

### 1. Was Sautero ist

Sautero ist eine **Beta-Version (Vorabversion) einer Küchenmanagement-Anwendung**, die täglich
aktiv weiterentwickelt wird. Funktionen können sich während des Pilotbetriebs ohne Ankündigung
ändern, ausfallen oder entfernt werden. Es handelt sich noch nicht um ein fertiges, kommerziell
unterstütztes Produkt; eine bestimmte Verfügbarkeit, ein Funktionsumfang oder ein Support-Level
werden nicht zugesichert.

### 2. Konten und Zugang

- Der Zugang erfolgt **nur auf Einladung**. Jedes Teammitglied erhält ein eigenes Konto
  (E-Mail + Passwort; optional eine geräteinterne Face-ID-/Fingerabdruck-Entsperrung —
  biometrische Daten verlassen das Gerät nie).
- Vor der ersten Nutzung akzeptiert jedes Teammitglied in der App einen Vertraulichkeits- und
  einen Datenschutzhinweis. Die Küche stellt sicher, dass ihr Personal weiss, dass die Nutzung
  von Sautero Teil des Pilotbetriebs ist.
- Es gibt zwei Kontomodi: **Company** (der gemeinsame Arbeitsbereich der Küche) und
  **Personal** (das private Notizbuch einer Einzelperson). Als «Personal» gespeicherte Inhalte
  sind auf Datenbankebene privat — die Küche und ihre Administratoren können sie nicht lesen;
  sie fallen **nicht** unter die Regel «gehört der Küche» in Ziffer 3.

### 3. Daten

- Alles, was in den gemeinsamen Arbeitsbereich der Küche eingegeben wird — Rezepte,
  Mise-en-place-Listen, Zutatenpreise, Bestellungen, Etiketten-Protokolle, HACCP-Aufzeichnungen,
  Dienstpläne, Arbeitszeiterfassung, Fotos — **gehört der Küche**.
- Die Daten werden bei Supabase gespeichert, einem Drittanbieter für verwaltete Datenbanken.
  Der Entwickler verkauft oder teilt die Daten der Küche nicht und verwendet sie zu keinem
  anderen Zweck als dem Betrieb der App.
- **Arbeitszeiten sind echte Mitarbeiterdaten** und werden mit besonderer Sorgfalt behandelt:
  - Ein-/Ausstempelzeiten, Pausen und Tagesnotizen sind für das jeweilige Teammitglied
    sichtbar. Ein Küchenadministrator sieht die Stunden des Teams **nur als anonyme Summe**,
    es sei denn, ein Teammitglied willigt individuell ein (in den eigenen Einstellungen,
    jederzeit widerrufbar), dass sein Name neben seinen Stunden angezeigt wird.
  - Beim Ein- und Ausstempeln erfasst die App eine **einmalige GPS-Standortaufnahme** (niemals
    eine kontinuierliche Ortung). Sie ist für das Teammitglied in seiner eigenen Tagesansicht
    sichtbar und wird zu keinem anderen Zweck verwendet.
- Die App führt technische Basisprotokolle (Logins, geöffnete Bereiche, JavaScript-Fehler),
  um die Nutzung des Piloten zu sehen und Fehler zu beheben; diese sind nur für den Entwickler
  sichtbar. E-Mail-Adressen, die Sautero erreichen (Zugangsanfragen, Einladungen), werden in
  einem internen Kontaktverzeichnis geführt.
- Die Küche kann jederzeit einen Export ihrer Daten oder deren Löschung verlangen (Ziffer 8).

### 4. KI-Funktionen

- Einige Funktionen (Foto-/PDF-/Excel-Scan von Rezepten, Menüs, Preislisten, Dienstplänen oder
  Verträgen; Rezeptgenerierung; Feldvorschläge; der Chef's-Assistant-Chat) senden den
  betreffenden Text oder das Bild zur Verarbeitung an die **Claude-API von Anthropic**, über
  den eigenen Server und den eigenen API-Schlüssel von Sautero. Über die Standard-API-Bedingungen
  von Anthropic hinaus werden keine Daten zum Training von KI-Modellen verwendet.
- Während des Pilotbetriebs sind die KI-Funktionen für die Küche **kostenlos**, im Rahmen einer
  fairen Nutzung.
- Beim Speichern eines Rezepts kann die App fragen, ob die Autorin/der Autor das Rezept **der
  gemeinsamen Sautero-Bibliothek beisteuern** möchte. Dies ist freiwillig und gilt pro Rezept.
  Beigesteuerte Rezepte können vom Entwickler geprüft und bei Annahme in die Bibliothek
  aufgenommen werden, die anderen Sautero-Küchen zur Verfügung steht. Ein Beitrag kann auf
  Anfrage zurückgezogen werden; bereits an andere Küchen verteilte Kopien können dort
  verbleiben.
- KI-Ausgaben (vorgeschlagene Daten, Mengen, Texte, Übersetzungen) können falsch sein. Eine
  Fachperson prüft sie vor der Verwendung — siehe Ziffer 5.

### 5. Lebensmittelsicherheit (HACCP) — Haftungsausschluss

Sautero kann Haltbarkeitsdaten («use by») vorschlagen, Etiketten für die Lebensmittelsicherheit
erzeugen und HACCP-Aufzeichnungen speichern (Temperaturen, Reinigungs-Checklisten, Ölwechsel,
Schädlingskontrollen) — auf Basis der in die App eingegebenen Informationen. **Dies sind
Hilfsmittel für den eigenen Lebensmittelsicherheitsprozess der Küche — sie ersetzen weder die
eigenen HACCP-Verfahren der Küche noch Schulung oder fachliches Urteil.** Die Küche bleibt
allein dafür verantwortlich, jedes Datum, Etikett, jede Temperatur und Aufzeichnung vor deren
Verwendung zu überprüfen. Der Entwickler übernimmt keine Haftung für Folgen im Bereich der
Lebensmittelsicherheit aus der Nutzung der App während des Pilotbetriebs.

### 6. Kostenlos, unverbindlich

Die Teilnahme am Pilotbetrieb ist **kostenlos und freiwillig**. Die Küche verpflichtet sich
nicht, zahlende Kundin zu werden; der Entwickler verpflichtet sich zu keinem Funktionsumfang,
Zeitplan oder Support-Level. Ein allfälliges künftiges kostenpflichtiges Angebot (z. B. ein
Founding-Member-Abonnement) wäre eine separate, freiwillige Vereinbarung.

### 7. Verfügbarkeit und Haftung

Sautero wird **«wie besehen»** («as is») bereitgestellt, ohne Gewährleistung. Der Entwickler
bemüht sich in zumutbarem Rahmen, die App am Laufen und die Daten sicher zu halten (verwaltetes
Hosting, Backups des Anbieters, Zugriffskontrollen), garantiert jedoch weder Verfügbarkeit noch
Fehlerfreiheit. Soweit nach schweizerischem Recht zulässig, ist die Haftung des Entwicklers aus
diesem Pilotbetrieb ausgeschlossen; die zwingende Haftung (rechtswidrige Absicht, grobe
Fahrlässigkeit) bleibt unberührt.

### 8. Laufzeit und Beendigung

Jede Partei kann den Pilotbetrieb **jederzeit, ohne Angabe von Gründen und ohne Nachteil**
beenden. Auf Anfrage werden die Daten der Küche innert 30 Tagen in einem gängigen Format
exportiert und/oder gelöscht. Die Ziffern 5 und 7 gelten über das Ende des Pilotbetriebs hinaus.

### 9. Rollen im Datenschutz

Für die in Sautero bearbeiteten Personendaten ihres Teams ist die Küche Verantwortliche
(Controller); der Entwickler bearbeitet diese Daten im Auftrag der Küche zum Zweck des Betriebs
der App (Auftragsbearbeiter; schweizerisches nDSG, ggf. DSGVO). Die Einzelheiten dieser
Rollenverteilung sind Teil der juristischen Prüfung (siehe Fragen am Ende).

### 10. Anwendbares Recht und Sprachen

Diese Vereinbarung untersteht **schweizerischem Recht**; Gerichtsstand ist Bern (zu
bestätigen). Sie wird in einer englischen und einer deutschen Fassung mit identischer
Nummerierung unterzeichnet. Bei Abweichungen geht die **deutsche Fassung** vor.

### 11. Kontakt

Fragen oder Probleme während des Pilotbetriebs: __________________________ (Kontakt Richard)

**Unterschriften:**

Vertretung der Küche: _________________________ Datum: _____________

Richard Červenka (Sautero): _________________________ Datum: _____________

---

## Fragen an den Anwalt / Otázky pre právnika

1. **Datenschutz-Rollen (Ziff. 9):** Genügt die Formulierung, oder braucht es einen separaten
   Auftragsbearbeitungsvertrag (ADV/DPA) zwischen Küche und Entwickler — insbesondere wegen
   der Arbeitszeit- und GPS-Daten der Mitarbeitenden?
2. **GPS & Mitarbeiterdaten (Ziff. 3):** Reicht die Kombination aus diesem Vertrag + In-App-
   Einwilligungen (Datenschutzhinweis, individuelles Opt-in für namentliche Stunden) nach nDSG
   für die einmalige GPS-Aufnahme beim Ein-/Ausstempeln? Muss die Küche ihre Mitarbeitenden
   zusätzlich schriftlich informieren?
3. **Haftungsausschluss (Ziff. 5 und 7):** Hält der Ausschluss in dieser Form vor
   schweizerischem Recht (OR 100)? Bitte Formulierung schärfen, wo nötig.
4. **Rezept-Beiträge (Ziff. 4):** Ist die Rechteeinräumung für der Bibliothek beigesteuerte
   Rezepte ausreichend geregelt (Nutzungsrecht für Sautero und andere Küchen, Widerruf), oder
   braucht es eine ausdrückliche Lizenzklausel?
5. **Arbeitgeber/IP:** Der Entwickler ist unselbständig in einer Küche angestellt
   (Nebenerwerb gemeldet). Gibt es aus der IP-Klausel des Arbeitsvertrags Risiken für die in
   Sautero entstehenden Inhalte, und gehört dazu ein Satz in diese Vereinbarung?
6. **Sprachen & Gerichtsstand (Ziff. 10):** Ist «deutsche Fassung geht vor» + Gerichtsstand
   Bern die richtige Wahl für Pilotküchen im Kanton Bern?

*Slovenská poznámka pre Richarda: obe verzie sú obsahovo totožné a číslovanie sedí 1:1, takže
právnik ich vie kontrolovať vedľa seba. Nič z tohto nie je právne poradenstvo — dokument je
pripravený presne na to, aby ho právnik roztrhal a vrátil lepší.*
