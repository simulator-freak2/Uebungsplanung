# Übungsplaner – Konzept v1.0

Planungssoftware für Übungen von **Feuerwehr**, **DLRG** und weiteren
Hilfsorganisationen (THW, DRK, ASB, Wasserwacht, JUH, MHD). Jede Organisation
betreibt ihre **eigene Installation**. Die App läuft **lokal** auf dem Gerät
und gleicht sich mit einem **eigenen Server** ab.

- Klickbare Vorschau: `vorschau/index.html`
- Anforderungen an Materialkompass: `docs/SCHNITTSTELLE_MATERIALKOMPASS.md`
- Lizenz: **EUPL-1.2** · Name: **Übungsplaner** · Repository vorerst privat

---

## 1. Ziele

1. **Ausführliche Übungsausarbeitung** mit allen Übungsunterlagen
2. **Jahresdienstplan**
3. **Qualifikationsverwaltung**, genutzt für die Fahrzeugbesetzung
4. **Lernen aus Übungen**: Die Nachbesprechung wird dokumentiert und fließt in die weitere Planung ein

Nicht Teil der App: Zu- und Absagen, Benachrichtigungen, Überwachung von Fristen.

## 2. Rahmen

| Punkt | Festlegung |
|---|---|
| Betrieb | eine Installation pro Organisation, ca. 5 gleichzeitige Nutzer |
| Zielgruppen | Erwachsene und Jugend |
| Rollen | Administrator, TL/Wehrführer (Freigabe), Planer/Ausbilder |
| Anmeldung | eigene Benutzerkonten der App |
| Personendaten | Name, Personalnummer, Qualifikationen; auch offline auf dem Tablet |
| Rechtsrahmen | DSGVO, BDSG, Landesrecht |
| Technik | Flutter (App), Dart (Server) |
| Farben | Rot / Gelb |
| Mehrbenutzer | letzte Änderung gilt (mit Hinweis) |

## 3. Funktionen

### 3.1 Übung (Übungsmappe)

Jede Übung besteht aus den folgenden Teilen. Alle sind einzeln und als gemeinsame Übungsmappe als PDF druckbar.

| Teil | Inhalt |
|---|---|
| **Übungsplan** | Eckdaten, Alarmstichwort, Lernziele, Lage, Ablauf in Phasen |
| **Sicherheit** | Gefährdungsbeurteilung als Pflicht-Checkliste |
| **Freigabe** | vom Admin ein- oder ausschaltbar; wenn eingeschaltet, gibt die Rolle TL/Wehrführer die Übung frei |
| **Lageskizze** | OpenStreetMap online; ohne Internet Offline-Karte des **Landkreises**; taktische Zeichen (DV 102, Wasserrettung) |
| **Fahrzeugbesetzung** | Besetzungsmuster je Fahrzeug wählen, Personen per **Drag & Drop** verschieben (Tablet: antippen), Prüfung der Qualifikation, Führungs- und Sonderfunktionen (Einsatzleiter, Übungsleitung, Sicherheitsbeauftragter, Beobachter, Mimenbetreuung …) |
| **Alarmierungsplan** | je Fahrzeug bzw. Trupp: Zeitpunkt von Alarmierung/Abruf, Ausrücken und Ankunft/Einsatzbeginn, Auslöser; als Tabelle und Zeitleiste |
| **Alarmmeldung** | nur Ausdruck; je Alarmierungszeitpunkt eine eigene Meldung; Aufbau wie die Divera-24/7-Meldung: Stichwort, Adresse, Sonderrechte/prioritär, Melder, alarmierte Fahrzeuge; deutlich als ÜBUNG gekennzeichnet |
| **Funkplan** | Rufname, Gerät, Funknetz (BOS digital TMO/DMO, BOS analog, DLRG-Betriebsfunk), Gruppe/Kanal, Aufgabe |
| **Rollenkarten (Mimen)** | Name, Geburtsdatum, Alter, Vorerkrankungen, Erkrankungen, Symptome, Verletzungen, Story, Eskalationsstufen |
| **Materialliste** | aus Materialkompass oder manuell |
| **Beobachtungsbogen** | Beobachtungspunkte je Übung, Bewertung (++ / + / o / –), Notizen |
| **Nachbesprechung** | Was lief gut, was muss besser werden, Maßnahmen mit Zuständigen und Status |

Erkenntnisse aus Nachbesprechungen erscheinen in der Übersicht und lassen sich in neue Übungen übernehmen.

### 3.2 Jahresdienstplan
Jahres- und Monatsansicht mit Kategorien. Ausgabe als PDF-Aushang, optional als iCal-Datei.

### 3.3 Vorlagen
Jede Übung lässt sich als Vorlage speichern und als Datei exportieren und importieren.

### 3.4 Stammdaten
- **Fahrzeuge & Funktionen**: Fahrzeuge und Boote werden zentral definiert, die Grunddaten kommen aus Materialkompass. Zu jedem Fahrzeug gehören Funktionen mit benötigter Qualifikation und mehrere **Besetzungsmuster** (z. B. Gruppe 1/8, Staffel 1/5, Trupp 1/2).
- **Führungs- und Sonderfunktionen** gelten unabhängig vom Fahrzeug.
- **Alarmstichworte**: zentrale Datenbank mit Stichwort, Kategorie, Beschreibung, Einsatzmitteln laut AAO und Sonderrechten. Import und Export als CSV oder Excel.
- **Personal**: Name, Personalnummer, Qualifikationen. Import aus Excel.
- **Funk**: Rufnamen, Gesprächsgruppen, Kanäle.
- **Organisationsprofil**: Begriffe, Qualifikations- und Funktionskataloge für Feuerwehr, DLRG und später weitere Organisationen.

### 3.5 Materialkompass
Material und Fahrzeuge werden übernommen. Wenn der Admin es freischaltet, können Planer Fahrzeuge direkt reservieren. Die Anforderungen stehen in `docs/SCHNITTSTELLE_MATERIALKOMPASS.md`.

## 4. Betriebsarten und Geräte

```
 Geräte: Windows · macOS · Linux (bearbeiten) | iPad · Android-Tablet (nur ansehen)
 ┌───────────────────────────────────────────────┐
 │ Flutter-App ── lokale Datenbank (SQLite)      │  arbeitet auch offline
 └───────────────▲───────────────────────────────┘
                 │ Abgleich über HTTPS (im LAN oder über VPN)
 ┌───────────────┴───────────────────────────────┐
 │ Übungsplaner-Server (Dart, eine Datei/Docker) │──► Materialkompass-API
 │ Linux · Windows · NAS · Raspberry Pi · Miete  │
 └───────────────────────────────────────────────┘
```

- **Nur lokal**: ein Gerät, kein Server.
- **Mit Server**: Die Geräte gleichen ab. Letzte Änderung gilt, mit Hinweis an den Planer.
- **Von zu Hause**: nur über **VPN**, kein offener Port. Der Admin schaltet das in den Einstellungen frei.
- Keine Browser-Version.

## 5. Technik

| Baustein | Wahl |
|---|---|
| App | Flutter 3, Material 3 mit eigenem Rot/Gelb-Design |
| Zustand/Architektur | Repository-Schicht, drift-Streams, `InheritedWidget` (bewusst ohne zusätzliches Framework) |
| Lokale DB | SQLite über `drift` |
| Server | Dart (`shelf`), ausgeliefert als ausführbare Datei (Linux/Windows, x64/ARM64) und als Docker-Image |
| Server-DB | SQLite |
| Abgleich | UUID + `updated_at` + `deleted` je Datensatz, Änderungsprotokoll, „letzte Änderung gilt“ |
| Karten | `flutter_map`, OpenStreetMap, Offline-Kacheln (MBTiles) je Landkreis |
| PDF | `pdf` / `printing` |
| Excel/CSV | `excel`, `csv` |
| Sicherheit | Argon2-Passwörter, Token-Anmeldung, HTTPS (selbstsigniertes Zertifikat mit Fingerprint-Bestätigung oder eigenes Zertifikat) |
| Qualität | Unit- und Widget-Tests; GitHub Actions für Tests und Builds (Windows, macOS, Linux) |
| Open Source | EUPL-1.2, README, CONTRIBUTING, Hinweise zu Drittlizenzen |

## 6. Datenmodell (Grobentwurf)

```
Organisation(Profil)
 ├─ Person(Name, Personalnr.) ── Qualifikation
 ├─ Fahrzeug(MK-ID, Funkrufname, Status) ─┬─ Funktion(benötigte Qualifikation)
 │                                         └─ Besetzungsmuster ── Funktion
 ├─ Führungsfunktion(benötigte Qualifikation)
 ├─ Alarmstichwort(Kategorie, AAO, Sonderrechte)
 ├─ Material(MK-ID | manuell)
 ├─ Funkressource(Netz, Gruppe/Kanal)
 └─ Übung ─┬─ Phase, Lernziel, Sicherheitscheck, Freigabe
           ├─ Besetzung(Fahrzeug, Muster, Funktion, Person)
           ├─ Alarmplan-Eintrag(Einheit, Alarm, Ausrücken, Ankunft, Auslöser)
           ├─ Alarmmeldung(Stichwort, Adresse, Sonderrechte, Melder, Fahrzeuge)
           ├─ Funkplan-Eintrag, Rollenkarte(+ Eskalationsstufen), Materialposition
           ├─ Beobachtung(Punkt, Bewertung, Notiz)
           ├─ Nachbesprechung ── Maßnahme(Zuständig, Status)
           ├─ Lageskizze(Kartenausschnitt, Zeichen)
           └─ Reservierung(MK-Reservierungs-ID, Status)
Vorlage = Übung ohne Datum           Benutzer ── Rolle(Admin | Planer)
```

## 7. Umsetzung in Etappen

| Etappe | Inhalt |
|---|---|
| 0 | ✅ Konzept, Vorschau, Schnittstellenanforderungen |
| 1 | ✅ Flutter-Projekt, Design, Stammdaten (Personal, Fahrzeuge, Funktionen, Besetzungsmuster, Stichworte), lokale DB |
| 2 | ✅ Übung: Übungsplan, Sicherheit, Freigabe, Fahrzeugbesetzung mit Drag & Drop, Alarmierungsplan, Alarmmeldung (Druck/PDF) |
| 3 | ✅ Funkplan, Rollenkarten, Material, Beobachtungsbogen (mit Katalog), Nachbesprechung, PDF-Übungsmappe, Beobachter-Ansicht, mehrere Alarmmeldungen je Alarmierungszeitpunkt |
| 4 | ✅ Jahresdienstplan, Vorlagen (inkl. Austausch als Datei), Excel-Import |
| 5 | ✅ Server, Benutzer und Rollen, Abgleich, Tablet-/Beobachter-Ansicht (nur lesen) |
| 6 | ✅ Lageskizze: Karte online/offline (MBTiles), taktische Zeichen, Bild in der Übungsmappe |
| 7 | ✅ Materialkompass-Anbindung (gegen Nachbildung der Schnittstelle getestet), Reservierung mit Genehmigung |
| 8 | ✅ Builds Windows/macOS/Linux/Android, Server für Linux (x64/ARM), Windows und Docker, Anleitungen |

## 8. Entscheidungen Runde 3

| # | Thema | Entscheidung |
|---|---|---|
| 1 | Divera | Nur Ausdruck der Alarmmeldung. Die Auslösung in Divera macht der TL. |
| 2 | Stichworte | Rheinland-Pfalz, Import aus der öffentlichen Stichworttabelle (CSV/Excel) |
| 3 | Alarmierungsplan | Uhrzeiten **und** relative Zeiten (Übungsbeginn + x Min.) möglich |
| 4 | Eskalationsstufen | stehen auf Rollenkarte, Beobachtungsbogen und in der Tablet-Ansicht der Übungsbeobachter |
| 5 | Beobachtungspunkte | frei je Übung **und** zentral als Katalog einspielbar |
| 6 | Freigabe | eigene Rolle **TL / Wehrführer** |
| 7 | Mehrfachfunktionen | eine Person darf mehrere Funktionen gleichzeitig haben |
| 8 | Taktische Zeichen | Quelle taktisches-zeichen.de (github.com/jonas-koeritz/Taktische-Zeichen). Die fertigen Zeichen aus den Releases sind CC0; der Quellcode steht unter CC BY 4.0. Namensnennung erfolgt trotzdem. Nach DV 102 organisationsneutral zusammengeführt (`app/tool/zeichen_dv102.py`); die App färbt Grundzeichen und Inhalt je Organisation ein. |
| 9 | Reservierung | in Materialkompass genehmigungspflichtig (Status `angefragt` → `bestaetigt`/`abgelehnt`) |
| 10 | Start | Etappe 1 freigegeben |

Rollen damit: **Administrator**, **TL / Wehrführer** (Freigabe), **Planer / Ausbilder**; Tablet-Ansicht für **Übungsbeobachter** (nur lesen).
