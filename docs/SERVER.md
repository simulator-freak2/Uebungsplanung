# Übungsplaner-Server einrichten

Mit dem Server arbeiten mehrere Geräte (PCs, Laptops, Tablets) mit denselben Daten.
Jedes Gerät arbeitet weiter, auch wenn der Server kurz nicht erreichbar ist; Änderungen
werden beim nächsten Kontakt abgeglichen. Bei gleichzeitigen Änderungen gilt die jüngere.

## 1. Server starten – eine der Varianten

### a) NAS (Synology, QNAP …) oder Linux-Server mit Docker – empfohlen

1. Ordner anlegen, z. B. `uebungsplaner`, und die Datei `server/docker-compose.yml` hineinlegen.
2. Im Ordner: `docker compose up -d`
   (Synology: *Container Manager → Projekt → Erstellen*, Datei auswählen.)
3. Die Daten liegen im Unterordner `daten/` – diesen Ordner mitsichern.

Das Image (`ghcr.io/simulator-freak2/uebungsplaner-server`) läuft auf Intel/AMD und ARM (z. B. Raspberry Pi 4/5).

### b) Raspberry Pi oder Linux ohne Docker

1. `Uebungsplaner-Server-Linux-arm64-RaspberryPi.tar.gz` (bzw. `…-x64`) aus dem GitHub-Lauf
   „Programme bauen“ herunterladen und nach `/opt/uebungsplaner-server` entpacken.
2. Die Schritte oben in `uebungsplaner-server.service` ausführen – der Server startet dann automatisch.

### c) Windows-PC

1. `Uebungsplaner-Server-Windows.zip` entpacken, z. B. nach `C:\Uebungsplaner-Server`.
2. `bin\uebungsplaner_server.exe --data C:\Uebungsplaner-Daten` starten.
3. Die Windows-Firewall fragt beim ersten Start – für **private Netzwerke** erlauben.
4. Automatisch starten: Aufgabenplanung → „Beim Systemstart“ → diese Befehlszeile.

### Optionen

| Option | Bedeutung | Standard |
|---|---|---|
| `--port` | Port | 8080 |
| `--data` | Ordner für die Datenbank | `daten` |
| `--host` | `127.0.0.1` = nur dieser Rechner | `0.0.0.0` (alle Netze) |
| `--cert`, `--key` | Zertifikat und Schlüssel (PEM) für HTTPS | aus |

## 2. Erstes Gerät verbinden

1. Im Übungsplaner: **Einstellungen → Mit Server verbinden**.
2. Adresse eingeben, z. B. `192.168.178.20:8080`, **Prüfen**.
3. Der Server ist neu: ersten **Administrator** anlegen. Die vorhandenen Daten des Geräts
   werden hochgeladen.

## 3. Benutzer anlegen

**Einstellungen → Benutzer & Rollen** (nur Administratoren):

| Rolle | Darf |
|---|---|
| Administrator | alles, Benutzer verwalten, gemeinsame Einstellungen |
| TL / Wehrführer | planen und **Übungen freigeben** |
| Planer / Ausbilder | planen, zur Freigabe vorlegen |
| Beobachter | nur lesen (für Tablets / Übungsbeobachter) |

Die Freigabe prüft der Server: Ein Planer kann eine Übung nicht freigeben, auch nicht mit
einem veränderten Programm.

## 4. Weitere Geräte

Beim ersten Start **„Mit vorhandenem Übungsplaner-Server verbinden“** wählen und anmelden –
alle Daten werden geladen. Tablets (Android-App `Uebungsplaner-Android-Tablet.apk`) zeigen
Übungen nur an (Beobachter-Ansicht, Übungsmappe drucken).

## 5. Zugriff von zu Hause

**Nur über VPN**, keinen Port im Router freigeben. Am einfachsten mit der FRITZ!Box:
*Internet → Freigaben → VPN (WireGuard)* einrichten und auf Laptop bzw. Tablet die
WireGuard-App verwenden. Dann ist der Server von unterwegs unter derselben Adresse
erreichbar wie im Gerätehaus.

Die Anmeldung läuft im eigenen Netz bzw. im VPN unverschlüsselt per HTTP; das VPN
verschlüsselt den Weg. Wer zusätzlich HTTPS möchte, startet den Server mit `--cert`/`--key`.

## 6. Sicherung

Sichert regelmäßig den Datenordner des Servers (`uebungsplaner-server.sqlite`). Für die
Wiederherstellung den Server beenden, die Datei zurückkopieren und neu starten.
Zusätzlich kann jedes Gerät unter **Einstellungen → Datensicherung** seinen Stand sichern.
