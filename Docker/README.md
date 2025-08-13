# Docker Setup Script für Debian

Dieses Skript installiert oder entfernt **Docker Engine** und das **Docker Compose Plugin** auf Debian-basierten Systemen.
Es kann mehrfach verwendet werden, ist idempotent und erkennt vorhandene Installationen.

## 📦 Features

- Installation der offiziellen Docker-Pakete aus dem Docker-APT-Repository
- Automatisches Einbinden des Docker-APT-Repos (falls nicht vorhanden)
- Optionale Aufnahme des aktuellen Benutzers in die `docker`-Gruppe
- Optionales Aktivieren von **Rootless Docker**
- Start/Stop von Docker-Diensten
- Sauberes Entfernen aller Docker-Komponenten inkl. Daten (optional)
- Testlauf mit dem offiziellen `hello-world`-Image

---

## ⚙️ Nutzung

```bash
chmod +x docker-setup.sh
