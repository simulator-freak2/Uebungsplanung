# Übungsplanung – Konzept (Entwurf v0.1)

Planungs- und Dokumentationswerkzeug für Übungs- und Ausbildungsdienste von
**Feuerwehr** und **DLRG** (bzw. weiteren Hilfsorganisationen). Die App läuft
**lokal auf einem Rechner** (Einzelplatz, offline) oder **im Netzwerk**
(ein Server, viele Nutzer per Browser).

> Status: Entwurf zur Abstimmung. Offene Punkte sind mit **[FRAGE]** markiert
> und am Ende gesammelt.

---

## 1. Ziele

1. Jahres-/Halbjahres-Dienstpläne schnell erstellen und veröffentlichen.
2. Einzelne Übungen strukturiert planen (Lernziele, Ablauf, Material, Personal,
   Fahrzeuge/Boote, Sicherheit).
3. Wiederverwendbare **Übungsbibliothek** (Vorlagen) aufbauen.
4. Teilnahme erfassen und **Ausbildungsnachweise / Pflichtstunden** auswerten.
5. Für beide Organisationen nutzbar, ohne dass eine die Begriffe der anderen
   sieht (konfigurierbare Organisationsprofile).
6. Datenschutzkonform (DSGVO), Daten bleiben auf eigener Hardware.

## 2. Zielgruppen & Rollen

| Rolle | Beispiele FW | Beispiele DLRG | Rechte |
|---|---|---|---|
| Administrator | Wehrführung, IT-Beauftragter | Vorstand, Technischer Leiter | Alles, Benutzer, Stammdaten |
| Planer / Ausbilder | Gruppenführer, Ausbilder | Ausbilder Rettungsschwimmen, Wachleiter | Übungen planen, Vorlagen pflegen, Anwesenheit |
| Mitglied | Einsatzkraft, Jugendfeuerwehr | Rettungsschwimmer, Jugend | Dienstplan sehen, Zu-/Absagen |
| Gast / Anzeige | Infobildschirm im Gerätehaus | Aushang Wachstation | Nur lesen |

## 3. Organisationsprofile (FW / DLRG)

Ein gemeinsamer Kern, die Fachlichkeit kommt aus einem **Profil**:

| Bereich | Feuerwehr | DLRG |
|---|---|---|
| Einheiten | Abteilung, Zug, Gruppe, Staffel, Trupp, JF | Ortsgruppe, Wasserrettungszug, Wachmannschaft, Jugend |
| Ressourcen | Fahrzeuge (HLF, LF, DLK, MTW …), Geräte | Boote, Fahrzeuge, Tauchausrüstung, Rettungsgeräte |
| Qualifikationen | Truppmann, Truppführer, AGT, Maschinist, Gruppenführer … | DRSA Bronze/Silber/Gold, Wasserretter, Bootsführer, Strömungsretter, Taucher, San … |
| Themenkatalog | FwDV 3/7/10/500, THL, Brandbekämpfung, Atemschutz … | Rettungsschwimmen, Bootsdienst, Strömungsrettung, Erste Hilfe … |
| Pflichtnachweise | z. B. Atemschutz-Belastungsübung jährlich | z. B. DRSA-Wiederholung, San-Fortbildung |

Profile sind als **Katalogdaten** (nicht im Code) hinterlegt und können lokal
ergänzt werden. Gemischte Übungen (z. B. FW + DLRG Eisrettung) werden
unterstützt.

## 4. Funktionsumfang

### 4.1 MVP (Version 1)
- **Dienstplan / Kalender**: Monats-, Wochen-, Listenansicht; Serientermine;
  Filter nach Einheit; Export PDF und iCal (Abo-Link im Netzwerkbetrieb).
- **Übungsplanung (Übungsblatt)**:
  - Titel, Datum/Zeit, Ort (inkl. Koordinaten/Karte optional), Einheit(en)
  - Thema aus Katalog, Lernziele, Dauer
  - Ablaufplan in Phasen (Einweisung – Durchführung – Nachbesprechung)
  - Lage-/Szenariobeschreibung, Einspielungen
  - Benötigtes Material, Fahrzeuge/Boote
  - Verantwortliche (Leitung, Sicherheitsbeauftragter, Ausbilder)
  - **Sicherheitshinweise / Gefährdungsbeurteilung** (Checkliste)
  - Anhänge (PDF, Bilder, Skizzen)
  - Druckansicht als Übungsblatt (PDF)
- **Übungsbibliothek**: Übung als Vorlage speichern, kopieren, verschlagworten.
- **Mitglieder & Qualifikationen** (Basis): Name, Einheit, Qualifikationen
  mit Ablaufdatum.
- **Anwesenheit**: Teilnehmerliste je Übung, Stunden automatisch.
- **Auswertung**: Stunden je Mitglied/Einheit/Thema; Hinweis auf fällige
  Pflichtübungen.
- **Benutzer & Rollen**, Login (im Lokalmodus optional).
- **Datensicherung**: Backup/Restore als eine Datei.

### 4.2 Spätere Ausbaustufen (Vorschläge)
- Zu-/Absage durch Mitglieder, Erinnerungen per E-Mail
- Bewertung/Nachbesprechung mit Mängelliste („Lessons learned“)
- Ressourcen-Konfliktprüfung (Fahrzeug/Boot doppelt verplant)
- Import/Export: CSV, Anbindung an bestehende Systeme (siehe Fragen)
- Mobile-optimierte Ansicht/PWA, Offline-Synchronisation
- Mehrmandantenfähigkeit (mehrere Wehren/Ortsgruppen auf einem Server)
- Infobildschirm-Modus

## 5. Betriebsmodi

| | Lokal (Einzelplatz) | Netzwerk (Server) |
|---|---|---|
| Start | Doppelklick, öffnet Browser/Fenster | Dienst auf Server/NAS/Raspberry Pi/Docker |
| Datenbank | SQLite-Datei | SQLite (klein) oder PostgreSQL (größer) |
| Nutzer | 1 – wenige an einem Gerät | viele, gleichzeitig, per Browser |
| Login | optional | Pflicht |
| Internet | nicht nötig | nicht nötig (LAN), optional extern über HTTPS/VPN |

**Kernidee: dieselbe Anwendung** – ein Webserver mit Browser-Oberfläche.
Lokal lauscht er nur auf `127.0.0.1`, im Netzwerk auf der LAN-Adresse. Ein
Umschalten per Konfiguration genügt; eine lokale Datenbank kann später auf den
Server übernommen werden.

## 6. Technischer Vorschlag

- **Backend**: Python 3 + FastAPI (alternativ Node.js/TypeScript)
- **Datenbank**: SQLite (Standard), PostgreSQL optional; ORM SQLAlchemy +
  Migrationen (Alembic)
- **Frontend**: Web-Oberfläche (z. B. Vue oder React), responsive für Tablet/Handy
- **PDF**: serverseitige Erzeugung (z. B. WeasyPrint)
- **Auslieferung**:
  - Lokal: Windows-Installer / portable EXE (PyInstaller), optional
    Desktop-Fenster
  - Netzwerk: Docker-Image + docker-compose; alternativ Linux-Dienst
- **Sicherheit**: Passwort-Hashing (Argon2), Rollenrechte, HTTPS im
  Netzwerkbetrieb (Reverse Proxy), Audit-Log, verschlüsselte Backups optional
- **Datenschutz**: nur notwendige Personendaten, Lösch-/Exportfunktion,
  Rechtekonzept für Qualifikationsdaten

## 7. Datenmodell (Grobentwurf)

```
Organisation ─┬─ Einheit ── Mitglied ── Qualifikation(Ablauf)
              ├─ Ressource (Fahrzeug/Boot/Gerät)
              ├─ Thema/Katalog
              └─ Übung ─┬─ Ablaufphase
                        ├─ Zuordnung Einheit/Ressource/Verantwortliche
                        ├─ Sicherheitscheckliste
                        ├─ Anhang
                        └─ Teilnahme (Mitglied, Stunden, Status)
Vorlage (= Übung ohne Termin)   Benutzer ── Rolle
```

## 8. Vorgehen

1. Fragen klären (unten) → Konzept v1.0
2. Klickbarer Prototyp der Oberfläche (Dienstplan + Übungsblatt)
3. MVP-Entwicklung in Iterationen, je Iteration lauffähige Version
4. Testbetrieb in einer Wehr / Ortsgruppe, Feedback
5. Installer + Docker-Paket, Handbuch

---

## 9. Offene Fragen

### A. Einsatzumfang
1. Für **eine** Feuerwehr/Ortsgruppe oder für **mehrere** Organisationen auf einem Server (Mandanten)?
2. Wie viele Nutzer gleichzeitig, wie viele Mitglieder insgesamt (ungefähr)?
3. Soll eine Installation FW **und** DLRG gleichzeitig enthalten (gemeinsame Übungen), oder je Installation eine Organisation?
4. Gibt es weitere Organisationen (THW, DRK, ASB, Wasserwacht, JUH, MHD)?
5. Nur Erwachsene oder auch Jugendfeuerwehr / DLRG-Jugend (Jugendschutz, Eltern)?

### B. Funktionen
6. Was ist am wichtigsten: Jahresdienstplan, detaillierte Übungsausarbeitung, Anwesenheit/Stunden oder Qualifikationsverwaltung? (Reihenfolge)
7. Sollen Mitglieder selbst zu-/absagen können?
8. Benachrichtigungen per E-Mail/Messenger nötig? Gibt es einen Mailserver?
9. Brauchen wir eine Gefährdungsbeurteilung/Sicherheitscheckliste als Pflichtfeld?
10. Sollen Pflichtübungen/Fristen überwacht werden (z. B. Atemschutz, DRSA)? Welche konkret?
11. Kartenfunktion (Übungsort auf Karte, Skizzen)? Online-Karten erlaubt oder strikt offline?
12. Welche Ausdrucke/Exporte braucht ihr (Dienstplan-Aushang, Übungsblatt, Anwesenheitsliste, Jahresbericht)? Gibt es Vorlagen/Formulare, die nachgebildet werden sollen?
13. Gibt es vorhandene Daten (Excel-Listen, alte Dienstpläne) zum Import?
14. Anbindung an vorhandene Systeme gewünscht (z. B. FeuerOn, MP-Feuer, DLRG-ISC/Mitgliederverwaltung, Kalender wie Outlook/Google)?

### C. Betrieb & Technik
15. Lokaler Betrieb: Welches Betriebssystem (Windows, macOS, Linux)?
16. Netzwerkbetrieb: Auf welcher Hardware (Windows-PC, Linux-Server, NAS z. B. Synology, Raspberry Pi, gemieteter Server/Cloud)? Ist Docker möglich?
17. Nur im internen Netz (Gerätehaus/Wachstation) oder auch von zu Hause / unterwegs erreichbar?
18. Muss die App am Handy/Tablet gut bedienbar sein (z. B. Anwesenheit am Übungsort)? Offline am Übungsort nötig?
19. Soll man einen lokal begonnenen Datenbestand später auf einen Server umziehen oder synchronisieren können?
20. Wer betreibt/wartet die Installation (technische Vorkenntnisse)?

### D. Benutzer, Sicherheit, Datenschutz
21. Login-Verfahren: eigene Benutzerkonten genügt, oder Anbindung an vorhandene Konten (z. B. Microsoft 365, LDAP)?
22. Sind die vorgeschlagenen Rollen passend? Weitere Rollen?
23. Welche Personendaten dürfen gespeichert werden (Name, Kontakt, Geburtsdatum, Qualifikationen, Gesundheitsdaten wie G26.3 – letzteres sensibel)?
24. Gibt es Vorgaben eures Trägers (Kommune/Landesverband) zu Datenschutz oder IT?

### E. Rahmen
25. Sprache nur Deutsch?
26. Lizenz/Weitergabe: nur intern, oder Open Source für andere Wehren/Ortsgruppen?
27. Gibt es Vorlieben bei der Technik (Programmiersprache, Framework) oder Vorgaben?
28. Gibt es einen Zeitrahmen / Wunschtermin für eine erste nutzbare Version?
29. Gewünschtes Design (Farben FW rot / DLRG gelb-rot, Logos verwendbar)?
