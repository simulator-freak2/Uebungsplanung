# Anforderungen an die Materialkompass-Schnittstelle (API)

Version 1.0 · Stand: 22.11.2026 · für: materialkompass.org
Nutzer der Schnittstelle: **Übungsplaner** (Flutter-App und Übungsplaner-Server)

Ziel: Der Übungsplaner übernimmt **Material und Fahrzeuge** aus Materialkompass
und kann **Fahrzeuge für Übungen reservieren**, wenn die Admins das freigeschaltet haben.

Kennzeichnung: **MUSS** = für Version 1 nötig, **SOLL** = sehr hilfreich,
**KANN** = später.

---

## 1. Allgemein

| # | Anforderung | Stufe |
|---|---|---|
| A1 | REST-Schnittstelle mit JSON über **HTTPS** (TLS 1.2 oder neuer) | MUSS |
| A2 | Versionierter Pfad, z. B. `https://materialkompass.org/api/v1/…`. Inkompatible Änderungen nur in einer neuen Version (`/v2`) | MUSS |
| A3 | Beschreibung als **OpenAPI 3** (`/api/v1/openapi.json`) | SOLL |
| A4 | Zeichensatz UTF-8 (Umlaute in Bezeichnungen) | MUSS |
| A5 | Zeitangaben nach ISO 8601 mit Zeitzone, z. B. `2027-03-04T19:00:00+01:00` | MUSS |
| A6 | Jeder Datensatz hat eine **stabile, eindeutige ID** (UUID empfohlen), die sich nie ändert, auch nicht bei Umbenennung | MUSS |
| A7 | Jeder Datensatz hat `aktualisiert_am` (Zeitpunkt der letzten Änderung) | MUSS |
| A8 | Fehler als JSON nach RFC 9457 („Problem Details“) mit verständlicher deutscher Meldung | SOLL |
| A9 | Testumgebung oder Test-Organisation mit Beispieldaten | SOLL |

## 2. Anmeldung und Berechtigungen

| # | Anforderung | Stufe |
|---|---|---|
| B1 | Anmeldung mit **API-Schlüssel je Organisation** im Header `Authorization: Bearer <schlüssel>` | MUSS |
| B2 | Der Schlüssel wird von einem Materialkompass-Admin erzeugt, kann gesperrt und neu erzeugt werden | MUSS |
| B3 | Ein Schlüssel sieht nur die Daten **seiner** Organisation | MUSS |
| B4 | Berechtigungen (Scopes) am Schlüssel: `material:lesen`, `fahrzeuge:lesen`, `reservierungen:schreiben` | MUSS |
| B5 | Ohne `reservierungen:schreiben` wird jede Reservierung mit `403` abgelehnt. So kann auch Materialkompass das Reservieren sperren | MUSS |
| B6 | Anzeige im Materialkompass, wann ein Schlüssel zuletzt benutzt wurde | KANN |

## 3. Abgleich (Synchronisation)

Der Übungsplaner arbeitet auch offline. Er holt deshalb regelmäßig nur die Änderungen ab.

| # | Anforderung | Stufe |
|---|---|---|
| C1 | Alle Listen unterstützen `?geaendert_seit=<Zeitpunkt>` und liefern nur geänderte Datensätze | MUSS |
| C2 | Gelöschte Datensätze werden **nicht weggelassen**, sondern mit `"geloescht": true` geliefert (mindestens 90 Tage lang) | MUSS |
| C3 | Seitenweise Abfrage: `?limit=` (max. 500) und `?cursor=`; Antwort enthält `naechster_cursor` | MUSS |
| C4 | Antwort enthält `server_zeit`, damit der nächste Abruf genau dort weitermachen kann | SOLL |
| C5 | Antwortzeit unter 2 Sekunden für 500 Datensätze | SOLL |

Antwortformat für Listen:

```json
{
  "daten": [ ... ],
  "naechster_cursor": "eyJpZCI6IjEyMyJ9",
  "server_zeit": "2027-03-01T18:00:00+01:00"
}
```

## 4. Endpunkte

### 4.1 Status
`GET /api/v1/status` (MUSS) gibt `{ "version": "1.0.0", "organisation": { "id": "…", "name": "FF Musterstadt" } }` zurück.
Damit prüft der Übungsplaner beim Einrichten Adresse und Schlüssel.

### 4.2 Standorte
`GET /api/v1/standorte` (SOLL)

| Feld | Typ | Beispiel |
|---|---|---|
| id | UUID | |
| bezeichnung | Text | „Gerätehaus Nord“ |
| aktualisiert_am, geloescht | | |

### 4.3 Fahrzeuge (MUSS)
`GET /api/v1/fahrzeuge` und `GET /api/v1/fahrzeuge/{id}`

| Feld | Typ | Pflicht | Beispiel / Hinweis |
|---|---|---|---|
| id | UUID | ja | |
| bezeichnung | Text | ja | „HLF 20“, „MZB Musterstadt 1“ |
| typ | Text | ja | „HLF 20“, „RW“, „Motorrettungsboot“ |
| art | Auswahl | ja | `fahrzeug`, `boot`, `anhaenger` |
| funkrufname | Text | nein | „Florian Musterstadt 1/46-1“ |
| kennzeichen | Text | nein | |
| standort_id | UUID | nein | |
| sitzplaetze | Zahl | nein | 9 |
| status | Auswahl | ja | `einsatzbereit`, `bedingt_einsatzbereit`, `ausser_dienst`, `werkstatt` |
| status_hinweis | Text | nein | „Pumpe defekt“ |
| aktualisiert_am | Zeit | ja | |
| geloescht | bool | ja | |

Hinweis: Funktionen und Besetzungsmuster pflegt der Übungsplaner selbst. Materialkompass muss sie **nicht** kennen.

### 4.4 Material (MUSS)
`GET /api/v1/material` mit Filtern `?standort_id=`, `?fahrzeug_id=`, `?kategorie=`, `?suche=`

| Feld | Typ | Pflicht | Beispiel / Hinweis |
|---|---|---|---|
| id | UUID | ja | |
| bezeichnung | Text | ja | „Hydraulischer Rettungssatz“ |
| kategorie | Text | nein | „Technische Hilfe“ |
| inventarnummer | Text | nein | |
| menge | Zahl | ja | 2 |
| einheit | Text | nein | „Stück“, „Sack“ |
| verlastet_auf_fahrzeug_id | UUID | nein | wenn auf einem Fahrzeug |
| standort_id | UUID | nein | wenn im Lager |
| lagerort | Text | nein | „Regal 3, Fach B“ |
| status | Auswahl | ja | `einsatzbereit`, `pruefung_faellig`, `defekt`, `reparatur`, `ausgesondert` |
| naechste_pruefung | Datum | nein | |
| aktualisiert_am, geloescht | | ja | |

### 4.5 Verfügbarkeit von Fahrzeugen (MUSS)
`GET /api/v1/fahrzeuge/{id}/verfuegbarkeit?von=…&bis=…`

```json
{
  "fahrzeug_id": "…",
  "verfuegbar": false,
  "belegungen": [
    { "von": "2027-03-04T18:00:00+01:00", "bis": "2027-03-04T20:00:00+01:00",
      "grund": "Reservierung", "zweck": "Ausbildung Maschinisten" }
  ]
}
```

### 4.6 Reservierungen (MUSS)

| Methode | Pfad | Zweck |
|---|---|---|
| POST | `/api/v1/reservierungen` | Reservierung anlegen |
| GET | `/api/v1/reservierungen?referenz=…` | Reservierungen zu einer Übung abrufen |
| GET | `/api/v1/reservierungen/{id}` | einzelne Reservierung |
| PATCH | `/api/v1/reservierungen/{id}` | Zeitraum oder Zweck ändern |
| DELETE | `/api/v1/reservierungen/{id}` | Reservierung stornieren |

Anfrage beim Anlegen:

```json
{
  "fahrzeug_id": "…",
  "von": "2027-03-04T19:00:00+01:00",
  "bis": "2027-03-04T21:30:00+01:00",
  "zweck": "Übung: THL Verkehrsunfall",
  "referenz": "uebungsplaner:3f2c…",      // ID der Übung im Übungsplaner
  "angelegt_von": "j.becker"               // Benutzername, keine weiteren Personendaten
}
```

Antwort `201 Created`:

```json
{ "id": "…", "status": "bestaetigt", "fahrzeug_id": "…", "von": "…", "bis": "…",
  "referenz": "uebungsplaner:3f2c…", "aktualisiert_am": "…" }
```

| # | Anforderung | Stufe |
|---|---|---|
| R1 | Doppelbuchung wird mit `409 Conflict` abgelehnt; die Antwort nennt die kollidierende Belegung | MUSS |
| R2 | Header `Idempotency-Key`: Wird dieselbe Anfrage erneut gesendet (z. B. nach Verbindungsabbruch), entsteht **keine** zweite Reservierung | MUSS |
| R3 | `status` ist `bestaetigt`, `angefragt` (falls Materialkompass eine Genehmigung verlangt), `abgelehnt` oder `storniert` | MUSS |
| R4 | Der Übungsplaner darf nur Reservierungen ändern oder stornieren, die er selbst angelegt hat (gleicher Schlüssel) | MUSS |
| R5 | Reservierungen erscheinen im Materialkompass mit Zweck und Hinweis „aus Übungsplaner“ | SOLL |
| R6 | Fahrzeuge mit Status `werkstatt` oder `ausser_dienst` können nicht reserviert werden (`422`) | SOLL |
| R7 | Reservierung von Material (nicht nur Fahrzeugen) | KANN |

## 5. Betrieb, Sicherheit, Datenschutz

| # | Anforderung | Stufe |
|---|---|---|
| S1 | Begrenzung der Anfragen (z. B. 60 je Minute je Schlüssel), Antwort `429` mit `Retry-After` | SOLL |
| S2 | Über die Schnittstelle werden **keine Personendaten** übertragen, außer dem Benutzernamen bei Reservierungen | MUSS |
| S3 | Protokoll, welcher Schlüssel wann welche Reservierung angelegt oder geändert hat | SOLL |
| S4 | Server in der EU, Vertrag zur Auftragsverarbeitung (AVV) für die Organisationen verfügbar | SOLL |
| S5 | Ankündigung von Änderungen an der Schnittstelle mindestens 3 Monate vorher | SOLL |
| S6 | Webhooks bei Statusänderung eines Fahrzeugs | KANN |

## 6. Ablauf im Übungsplaner (zur Orientierung)

1. Der Admin trägt im Übungsplaner Adresse und API-Schlüssel ein. Danach wird `GET /status` geprüft.
2. Der Server des Übungsplaners holt alle 15 Minuten die Änderungen (`geaendert_seit`) und verteilt sie an die Geräte.
3. Ist **Reservieren** im Übungsplaner freigeschaltet, wählt der Planer in der Fahrzeugbesetzung „reservieren“:
   - Zuerst wird `verfuegbarkeit` geprüft, dann `POST /reservierungen` mit `Idempotency-Key` gesendet.
   - Ohne Verbindung wird die Reservierung vorgemerkt und beim nächsten Abgleich gesendet. Der Planer sieht dann „Reservierung ausstehend“.
4. Wird eine Übung verschoben oder gelöscht, wird die Reservierung geändert (`PATCH`) bzw. storniert (`DELETE`).
