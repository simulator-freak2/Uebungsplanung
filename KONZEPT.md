# Übungsplanung – Konzept (Entwurf v0.2)

Planungssoftware für Übungen von **Feuerwehr**, **DLRG** und weiteren
Hilfsorganisationen (THW, DRK, ASB, Wasserwacht, JUH, MHD). Jede Organisation
betreibt ihre **eigene Installation**. Die App läuft **lokal** auf einem Gerät
und kann sich mit einem **eigenen Server** abgleichen.

Vorschau (klickbar, mit fiktiven Beispieldaten): `vorschau/index.html`

> Status: v0.2 – Antworten aus Runde 1 eingearbeitet. Offene Punkte stehen in
> Abschnitt 10.

---

## 1. Ziele (Priorität)

1. **Ausführliche Übungsausarbeitung** inklusive aller Übungsunterlagen
2. **Jahresdienstplan**
3. **Qualifikationsverwaltung**, genutzt für die Fahrzeug- und Trupp-Einteilung

Ausdrücklich **nicht** Teil der App: Zu- und Absagen durch Mitglieder,
Benachrichtigungen, Überwachung von Fristen und Pflichtübungen. Die App ist ein
Planungswerkzeug für die Planer.

## 2. Rahmen

| Punkt | Festlegung |
|---|---|
| Betrieb | eine Installation pro Organisation |
| Nutzer | ca. 5 gleichzeitig |
| Zielgruppen | Erwachsene und Jugend (JF, DLRG-Jugend) |
| Rollen | **Administrator**, **Planer/Ausbilder** |
| Personendaten | nur Name, Personalnummer, Qualifikationen |
| Sprache | Deutsch |
| Rechtsrahmen | DSGVO, BDSG, Landesrecht |
| Lizenz | als Open Source vorbereiten |
| Technik | **Flutter** |
| Farben | Rot / Gelb |
| Betreuung | Projektinhaber selbst (wenig Erfahrung): Installation und Updates müssen sehr einfach sein |

## 3. Organisationsprofile

Der Kern ist für alle Organisationen gleich. Was sich unterscheidet, steht in einem Profil:

| Bereich | Feuerwehr | DLRG |
|---|---|---|
| Einheiten | Löschzug, Gruppe, Jugendfeuerwehr | Wasserrettungszug, Wachdienst, DLRG-Jugend |
| Fahrzeuge/Boote und Funktionen | HLF: GF, Ma, Me, A-/W-/S-Trupp | MZB: Bootsführer, Bootsgast, Strömungsretter |
| Qualifikationen | Truppmann, Truppführer, AGT, Maschinist, Gruppenführer | DRSA, Wasserretter, Bootsführer, Strömungsretter, Taucher |
| Rufnamen | z. B. „Florian …“ | z. B. „Pelikan …“ |

Profile sind Katalogdaten (JSON) und keine Programmlogik. Weitere Organisationen kommen später über neue Profile dazu.

## 4. Funktionen (Version 1)

### 4.1 Übung (Übungsmappe)
Zu jeder Übung gehören folgende Teile:

- **Übungsplan**: Eckdaten, Lernziele, Lage, Ablauf in Phasen, Übungsleitung, Sicherheitsbeauftragte/r
- **Sicherheit / Gefährdungsbeurteilung**: Pflicht-Checkliste. Ohne sie wird die Übung nicht freigegeben.
- **Lageskizze & Karte**: Online-Karten (OpenStreetMap) und Offline-Kartenpakete, Symbole zum Einzeichnen
- **Fahrzeug- und Trupp-Einteilung**: Sitzplan je Fahrzeug bzw. Boot mit Qualifikationsprüfung (Hinweis bei fehlender Qualifikation)
- **Funkplan / Kommunikationsplan**: Rufnamen, Gesprächsgruppen (TMO/DMO), Aufgaben
- **Rollenkarten für Mimen**: Rolle, Verletzungen, Verhalten, Schminkhinweise, Info nur für Mimen
- **Materialliste**: aus Materialkompass übernommen oder manuell ergänzt
- **Einsatzfax**: Übungs-Alarmdepesche, deutlich als „ÜBUNG“ gekennzeichnet
- **Export als PDF**: als komplette Übungsmappe oder jedes Dokument einzeln

### 4.2 Jahresdienstplan
Jahres- und Monatsansicht mit Kategorien (Praxis, Theorie, Sonderdienst, Jugend). Export als PDF-Aushang und optional als iCal.

### 4.3 Vorlagen
Jede Übung lässt sich als Vorlage speichern. Vorlagen können als Datei exportiert und importiert werden, um sie mit anderen Wehren oder Ortsgruppen zu teilen.

### 4.4 Personal & Qualifikationen
Gespeichert werden Name, Personalnummer und Qualifikationen. Bestehende Listen lassen sich per **Excel-Import** übernehmen.

### 4.5 Materialkompass-Anbindung
Material, Fahrzeuge und Standorte werden aus Materialkompass übernommen (Details siehe offene Fragen).

## 5. Betriebsarten

```
 ┌──────────────── Gerät (Windows/macOS/Linux/Tablet) ────────────────┐
 │ Flutter-App  ──  lokale Datenbank (SQLite)                        │
 └───────────────▲───────────────────────────────────────────────────┘
                 │ Abgleich (HTTPS, wenn Server erreichbar)
 ┌───────────────┴─── Server (Linux, Windows, NAS, Raspberry Pi, Mietserver) ─┐
 │ Übungsplaner-Server (Dart) – Datenbank – Benutzer/Rollen                   │
 │ optional: Zugriff von außen (vom Admin freigeschaltet, nur HTTPS)          │
 └───────────────────────────────────────────────────────────────────────────┘
```

- **Nur lokal**: Die App arbeitet allein, ganz ohne Server.
- **Mit Server**: Die App arbeitet offline weiter und gleicht ab, sobald der Server erreichbar ist (offline-first).
- **Tablet**: dieselbe App, für die Übungsvorbereitung. Übungen werden auf das Gerät geladen.

## 6. Technischer Vorschlag

| Baustein | Vorschlag | Grund |
|---|---|---|
| App | Flutter (Windows, macOS, Linux, iPadOS, Android) | Vorgabe; eine Codebasis |
| Lokale DB | SQLite über `drift` | stabil, offline |
| Server | **Dart** (z. B. `shelf`), als **eine ausführbare Datei** und als **Docker-Image** | gleiche Sprache wie die App, gemeinsamer Code, läuft auf x64 und ARM (Raspberry Pi) |
| Server-DB | SQLite (Standard), PostgreSQL optional | reicht für ca. 5 gleichzeitige Nutzer |
| Abgleich | Datensätze mit UUID, Änderungszeitpunkt und Versionszähler; Konfliktanzeige | offline-first |
| Karten | `flutter_map` + OpenStreetMap, Offline-Kacheln (MBTiles) | online und offline |
| PDF | `pdf`/`printing` (Dart) | gleiche Ausgabe auf allen Systemen |
| Excel | Paket `excel` | Import der vorhandenen Listen |
| Sicherheit | Argon2-Passwörter, Rollen, HTTPS, Audit-Log | Datenschutz |
| Open Source | Lizenzdatei, README, CONTRIBUTING, CI (GitHub Actions) | Veröffentlichung |

## 7. Datenmodell (Grobentwurf)

```
Organisation(Profil) ─┬─ Einheit
                      ├─ Person(Name, Personalnr.) ── Qualifikation
                      ├─ Fahrzeug/Boot ── Funktion(benötigte Qualifikation)
                      ├─ Material (Quelle: Materialkompass | manuell)
                      └─ Übung ─┬─ Phase, Lernziel, Sicherheitscheck
                                ├─ Einteilung(Fahrzeug, Funktion, Person)
                                ├─ Funkplan-Eintrag
                                ├─ Rollenkarte
                                ├─ Materialposition
                                ├─ Einsatzfax
                                └─ Lageskizze(Kartenausschnitt, Symbole)
Vorlage = Übung ohne Datum       Benutzer ── Rolle(Admin | Planer)
```

## 8. Vorgehen

1. ✅ Konzept v0.2 + klickbare Vorschau
2. Offene Fragen klären → Konzept v1.0
3. Flutter-Grundgerüst: lokale App mit Übung + Dienstplan
4. Übungsmappe komplett + PDF
5. Server + Abgleich
6. Materialkompass, Excel-Import, Karten offline
7. Installer und Docker-Image, Handbuch, Open-Source-Veröffentlichung

## 9. Antworten Runde 1 (Kurzfassung)

Eigene Installation je Organisation · 5 Nutzer · Erwachsene und Jugend ·
Priorität: Übungsausarbeitung > Dienstplan > Qualifikationen · keine Zusagen,
keine Benachrichtigungen, keine Fristen · Sicherheitscheck Pflicht · Karten
online und offline · Dokumente: Rollenkarten, Übungsplan, Einteilung,
Funkplan, Materialliste, Einsatzfax · Import aus Excel · Materialkompass ·
Windows/macOS/Linux · Server auf Linux, Windows, NAS, Raspberry Pi oder
Mietserver · Fernzugriff durch Admin einstellbar · Tablet · Abgleich ·
Rollen Admin und Planer · Name, Personalnr., Qualifikation · deutsches Recht ·
Open Source · Flutter · rot/gelb.

## 10. Offene Fragen (Runde 2)

### Materialkompass
1. Welches Produkt ist gemeint (Hersteller/Website)? Gibt es eine Schnittstelle (API) oder nur einen Export (CSV/Excel)?
2. Habt ihr einen Zugang, mit dem ich testen kann, oder eine Schnittstellenbeschreibung?
3. Welche Daten sollen übernommen werden: nur Material, oder auch Fahrzeuge, Standorte und Prüfstatus (z. B. „in Reparatur“)?
4. Nur lesen, oder soll die App auch etwas zurückschreiben (z. B. „Material für Übung reserviert“)?

### Übungsunterlagen
5. **Einsatzfax**: Habt ihr ein Muster eurer Leitstelle? Soll es nur ausgedruckt werden, oder auch auf einem Alarmmonitor bzw. per E-Mail ankommen?
6. **Rollenkarten**: Reichen die Felder der Vorschau (Rolle, Verletzungen, Verhalten, Schminken, Info)? Braucht ihr Vitalwerte (Puls, Blutdruck, SpO2) für den Sanitätsdienst?
7. **Funkplan**: Sollen Rufnamen und Gesprächsgruppen als Stammdaten gepflegt werden? Braucht ihr auch Kanalpläne für Analogfunk?
8. **Lageskizze**: Braucht ihr taktische Zeichen nach DV 102 (bzw. DLRG-Zeichen)?
9. Für welches Gebiet sollen Offline-Karten verfügbar sein (Landkreis, Bundesland)?
10. Gibt es weitere Unterlagen, z. B. Bewertungsbogen für Beobachter, Anwesenheitsliste oder Nachbesprechungsprotokoll?

### Abläufe
11. Braucht eine Übung eine **Freigabe** (z. B. durch die Wehrführung oder den TL), oder reicht der Sicherheitscheck?
12. Sollen nach der Übung **Teilnahme** und **Nachbesprechung** erfasst werden, oder endet die App mit der Planung?
13. Mehrere Planer an einer Übung: Reicht „letzte Änderung gewinnt mit Hinweis“, oder soll eine Übung beim Bearbeiten gesperrt werden?

### Betrieb
14. Fernzugriff: Gibt es eine feste Adresse (Domain) oder einen Router mit DynDNS? Wäre ein VPN (z. B. WireGuard/FRITZ!Box) eine Möglichkeit? Ich empfehle bei wenig Erfahrung VPN statt offener Ports.
15. Soll der Server zusätzlich eine **Browser-Version** anbieten (z. B. zum Ansehen von zu Hause ohne installierte App)?
16. Tablet: iPad, Android oder beides? Sollen Übungen auf dem Tablet auch **bearbeitet** werden oder nur angesehen?
17. Welche NAS-Marke ist vorhanden (z. B. Synology, QNAP)? Unterstützt sie Docker / Container Manager?

### Anmeldung & Daten
18. Frage 21 aus Runde 1 war unvollständig: Reichen **eigene Benutzerkonten** der App, oder soll zusätzlich eine Anmeldung über vorhandene Konten (Microsoft 365, LDAP, DLRG-/Verbandskonto) möglich sein?
19. Wie sehen eure **Excel-Listen** aus? Eine Beispieldatei mit Spaltenüberschriften (ohne echte Daten) wäre ideal.
20. Brauchen Planer auf dem Tablet auch offline Zugriff auf Personaldaten, oder genügt die Einteilung ohne Personalnummer?

### Open Source & Name
21. Welche Lizenz? Vorschlag: **EUPL-1.2** (europäisch, für Behörden und Vereine gut geeignet), sonst GPL-3.0 oder MIT.
22. Wie soll die App heißen? (Arbeitstitel: „Übungsplaner“)
23. Soll das GitHub-Repository öffentlich werden, sobald die erste Version fertig ist?
24. Gefällt euch das Design der Vorschau? Was fehlt, was soll anders sein?
