# Übungsplaner – Anleitung (Version 1.0)

## 1. Installieren

Die fertigen Programme baut GitHub automatisch (Workflow **„Programme bauen“**).

1. Im Repository auf **Actions → Programme bauen → Run workflow** klicken (oder einen Tag wie `v1.0.0` setzen).
2. Nach ca. 15 Minuten im Lauf unten unter **Artifacts** herunterladen:

| System | Datei | Starten |
|---|---|---|
| Windows | `Uebungsplaner-Windows.zip` | entpacken, `uebungsplaner.exe` starten |
| macOS | `Uebungsplaner-macOS.zip` | entpacken, `uebungsplaner.app` mit Rechtsklick → *Öffnen* (die App ist nicht von Apple signiert) |
| Linux | `Uebungsplaner-Linux.tar.gz` | entpacken, `./uebungsplaner` starten |

Die Daten liegen im Anwendungsdatenordner des Benutzers:

- Windows: `%APPDATA%\Uebungsplaner\Uebungsplaner\`
- macOS: `~/Library/Containers/de.uebungsplaner.uebungsplaner/Data/Library/Application Support/de.uebungsplaner.uebungsplaner/`
- Linux: `~/.local/share/de.uebungsplaner.uebungsplaner/`

Ein Update ersetzt nur das Programm, die Daten bleiben erhalten.

## 2. Erster Start

1. Name der Organisation eintragen und **Feuerwehr** oder **DLRG** wählen.
2. Zum Ausprobieren: **Einstellungen → Beispieldaten laden**. Das ist nur möglich, solange noch nichts angelegt ist.
3. Für den echten Betrieb:
   - **Personal**: Personen anlegen oder eine Excel-/CSV-Liste importieren (Spalten werden zugeordnet).
   - **Fahrzeuge & Funktionen**: Fahrzeuge aus Vorlagen anlegen (HLF 20, LF 10, RW, ELW 1, MRB, GW-Wasserrettung …). Funktionen, benötigte Qualifikationen und Besetzungsmuster prüfen.
   - **Alarmstichworte**: Stichworte anlegen oder per Excel/CSV importieren.
   - **Beobachtungspunkte**: zentralen Katalog anlegen oder importieren.

## 3. Eine Übung planen

**Übungen → Neue Übung** (oder **Dienstplan → +** im Monat, oder **Aus Vorlage**).

| Reiter | Was ihr dort macht |
|---|---|
| Übungsplan | Eckdaten, Lernziele, Lage, Ablauf, Sicherheits-Checkliste |
| Besetzung | Fahrzeuge einplanen, Besetzungsmuster wählen, Personen per **Drag & Drop** auf Funktionen ziehen (oder Person antippen → Funktion antippen). Gelb = Qualifikation fehlt. Eine Person darf mehrere Funktionen haben. Oben stehen die **Führungs- und Sonderfunktionen** dieser Übung: Jede Übung beginnt mit *Einsatzleiter / Einheitsführer*; über *+ Funktion* kommen beliebig weitere hinzu (Zugführer, Gruppenführer …, gleiche Namen sind erlaubt). Mit dem Stift: Name, unterstellt unter, Fahrzeug, Funkrufname, Qualifikation. Darunter die Rubrik **Übungsdurchführung** mit *Übungsleitung*, *Übungsbeobachter*, *Mimenbetreuung* und *Sicherheitsbeauftragter* als Vorgabe; über *+ Funktion* kommen weitere hinzu (z. B. ein zweiter oder dritter Übungsbeobachter, Schiedsrichter, Fotograf). Diese Funktionen erscheinen nicht im Organigramm. Die Führungsfunktionen in den Stammdaten dienen als Vorlagen. |
| Organigramm | Führungsstruktur als Grafik: oben der Einsatzleiter, darunter die unterstellten Führungskräfte – je Kästchen Funkrufname, Funktion, Person und Fahrzeug. Alles kommt live aus Besetzung und Funkplan: Person aus der Besetzung; Fahrzeug fest gewählt oder das Fahrzeug, auf dem die Person eingeteilt ist; Funkrufname aus dem verknüpften Funkplan-Eintrag, sonst vom Fahrzeug. Ein im Organigramm eingetragener Funkrufname wird im Funkplan angelegt bzw. verknüpft – Änderungen im Funkplan erscheinen sofort im Organigramm. *Drucken / PDF* erzeugt eine Seite im Querformat. |
| Alarmierungsplan | Wer wird wann alarmiert/abgerufen, rückt aus, ist vor Ort. Zeiten als Uhrzeit (`19:15`) oder ab Beginn (`+15`). |
| Alarmmeldung | Ausdruck im Aufbau der Divera-Meldung. **Je Alarmierungszeitpunkt eine eigene Meldung** (Erstalarm, Nachalarmierung …). Die Auslösung in Divera macht der TL. |
| Funkplan | Rufnamen, Funknetz (BOS digital/analog, DLRG-Betriebsfunk), Gruppe/Kanal, Aufgabe |
| Rollenkarten | Mimen mit Name, Geburtsdatum/Alter, Vorerkrankungen, Erkrankungen, Symptomen, Verletzungen, Story und **Eskalationsstufen** |
| Material | Materialliste |
| Beobachtung | Beobachtungspunkte (frei oder aus dem Katalog) mit Bewertung und Notiz; Eskalationsstufen der Mimen |
| Nachbesprechung | Was lief gut / besser machen, Maßnahmen mit Zuständigen. Offene Maßnahmen erscheinen in der **Übersicht** und lassen sich mit „In Übung übernehmen“ als Lernziel in eine kommende Übung übernehmen. |

Oben rechts:

- **Übungsmappe**: Teile auswählen und dann drucken oder als PDF speichern. Die Mappe enthält Übungsplan, Besetzung, Organigramm, Alarmierungsplan, alle Alarmmeldungen, Funkplan, je Mime eine Rollenkarte, Material, Beobachtungsbogen und Nachbesprechungsprotokoll.
- **Zur Freigabe vorlegen / Freigeben**: Das geht erst, wenn die Sicherheits-Checkliste vollständig ist. Die Freigabe erteilt TL oder Wehrführer mit Namen. Sie lässt sich in den Einstellungen abschalten.
- **⋮**: Beobachter-Ansicht (große Schrift, nur lesen, z. B. fürs Tablet), Als Vorlage speichern, Übung kopieren, Löschen.

## 4. Lageskizze und Karten

Reiter **Lageskizze** in jeder Übung:

- **Taktisches Zeichen** wählen (über 400 Zeichen von taktisches-zeichen.de, mit Suche) und auf die Karte tippen
- **Linie** (z. B. Absperrung, Schlauchleitung), **Fläche** (z. B. Gefahrenbereich, Suchabschnitt), **Text**
- Element antippen: beschriften, Farbe ändern, verschieben, löschen
- **Ort suchen** (benötigt Internet) oder die Karte von Hand verschieben
- **Für Übungsmappe übernehmen** speichert ein Bild; es erscheint als Seite „Lageskizze“ mit Legende in der Mappe

**Kartenquelle** (Einstellungen → Karten, gilt je Gerät):

- *Online*: OpenStreetMap
- *Offline*: eine **MBTiles-Datei** eures Landkreises
- *Offline, sonst online*: Offline-Karte, fehlende Bereiche aus dem Internet

**Offline-Karte erstellen** (einmalig, z. B. mit dem kostenlosen Programm QGIS):

1. In QGIS die amtliche Karte eures Landes als WMS-Dienst einbinden (Rheinland-Pfalz: Geobasisdaten des
   Landesamts für Vermessung und Geobasisinformation, frei nutzbar mit Quellenangabe) oder eine andere Karte, die ihr offline nutzen dürft.
2. *Verarbeitung → Werkzeugkiste → „XYZ-Kacheln erzeugen (MBTiles)“*: Ausdehnung = Landkreis,
   Zoom 10 bis 17 (für Einsatzstellen ggf. bis 18), Format PNG oder JPG.
3. Bei den Metadaten unter *Attribution* die Quellenangabe eintragen (erscheint auf Karte und Mappe).
4. Im Übungsplaner unter *Einstellungen → Karten → Datei wählen*.

Hinweis: Die Kacheln von tile.openstreetmap.org dürfen nicht massenhaft heruntergeladen werden; deshalb
erzeugt die App selbst keine Offline-Karten.

## 5. Materialkompass

**Einstellungen → Materialkompass**: Adresse der Schnittstelle und API-Schlüssel eintragen,
*Speichern und prüfen*, dann *Jetzt abgleichen*.

- **Fahrzeuge** werden über Bezeichnung oder Funkrufname zugeordnet; Status (z. B. „in Werkstatt“)
  und Funkrufname werden übernommen. Fehlende Fahrzeuge bietet die App zum Anlegen an.
- **Material** wird auf dem Gerät zwischengespeichert und steht in jeder Übung unter
  *Material → Aus Materialkompass* zur Auswahl (auch ohne Verbindung).
- **Reservierung**: Ein Administrator schaltet *Planer dürfen Fahrzeuge reservieren* ein. Dann zeigt die
  Fahrzeugbesetzung je Fahrzeug *In Materialkompass reservieren*. Reservierungen sind dort
  genehmigungspflichtig; der Status (angefragt / bestätigt / abgelehnt) wird angezeigt und lässt sich
  aktualisieren oder stornieren.

## 6. Dienstplan und Vorlagen

- **Dienstplan**: Jahresübersicht nach Monaten, farbig nach Kategorie (Praxis, Theorie, Sonderdienst, Jugend). Den Aushang gibt es als PDF oder direkt zum Drucken.
- **Vorlagen**: Aus einer Vorlage wird mit einem Klick eine neue Übung. Vorlagen lassen sich als Datei (`.uebung.json`) **exportieren und importieren**, z. B. für andere Wehren oder Ortsgruppen. Personen sind nie in der Datei. Fahrzeuge und Stichworte werden über ihren Namen zugeordnet.

## 7. Datensicherung

**Einstellungen → Datensicherung → Sichern** speichert eine komplette Kopie der Datenbank. Am besten regelmäßig sichern, z. B. auf einen USB-Stick.

Zurückspielen: Programm beenden und die Sicherungsdatei als `uebungsplaner.sqlite` in den Datenordner (siehe oben) kopieren.

## 8. Mehrere Geräte und Tablets

Siehe [`SERVER.md`](SERVER.md): Server einrichten, Benutzer und Rollen, Zugriff von zu Hause über VPN,
Android-App für Tablets (nur ansehen).

## 9. Was noch fehlt (geplant)

- Import der Stichworttabelle Rheinland-Pfalz (sobald die Quelle vorliegt)
- iPad-App (zum Verteilen ist ein Apple-Entwicklerkonto nötig; die App selbst ist vorbereitet)
