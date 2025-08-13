#!/usr/bin/env bash
# docker-setup.sh — Install/Uninstall Docker on Debian (Engine + Compose)
# Usage:
#   ./docker-setup.sh install            # Docker installieren (empfohlen)
#   ./docker-setup.sh install --rootless # Rootless-Setup zusätzlich vorbereiten
#   ./docker-setup.sh uninstall          # Docker komplett entfernen
#   ./docker-setup.sh test               # hello-world Testcontainer
#
# Optional flags with `install`:
#   --no-group     # nicht automatisch zur 'docker'-Gruppe hinzufügen
#   --no-enable    # Dienst nicht automatisch aktivieren/gestartet lassen

set -euo pipefail

log() { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
need_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || { err "Bitte als root oder via sudo ausführen."; exit 1; }; }
cmd_exists(){ command -v "$1" >/dev/null 2>&1; }

DEBIAN_CODENAME="$(. /etc/os-release; echo "${VERSION_CODENAME}")"
ARCH="$(dpkg --print-architecture)"

install_repo() {
  log "Docker APT-Repository einbinden (${DEBIAN_CODENAME}, ${ARCH})…"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${DEBIAN_CODENAME} stable
EOF
}

install_docker() {
  local add_group=1 enable_service=1 rootless=0
  for a in "$@"; do
    case "$a" in
      --no-group) add_group=0;;
      --no-enable) enable_service=0;;
      --rootless) rootless=1;;
      *) ;;
    esac
  done

  need_root
  log "Pakete aktualisieren…"
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release

  # Repo einrichten, falls nicht vorhanden
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    install_repo
  else
    log "Docker-Repo existiert bereits."
  fi

  log "Docker Engine + Compose installieren…"
  apt-get update -y
  apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  if [ "$enable_service" -eq 1 ]; then
    log "Dienst aktivieren & starten…"
    systemctl enable --now docker
  fi

  if [ "$add_group" -eq 1 ]; then
    local user="${SUDO_USER:-$USER}"
    if id -nG "$user" | grep -qw docker; then
      log "User '$user' ist bereits in der docker-Gruppe."
    else
      log "Füge '$user' zur docker-Gruppe hinzu…"
      usermod -aG docker "$user" || true
      warn "Damit die Gruppenänderung greift: einmal ab- und wieder anmelden oder 'newgrp docker' ausführen."
    fi
  fi

  if [ "$rootless" -eq 1 ]; then
    log "Rootless-Docker vorbereiten (optional)…"
    apt-get install -y uidmap dbus-user-session
    sudo -u "${SUDO_USER:-$USER}" sh -c 'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"; dockerd-rootless-setuptool.sh install || true'
    warn "Rootless gestartet. Für Nutzung: 'export DOCKER_HOST=unix:///run/user/$UID/docker.sock'"
  fi

  log "Installation fertig. Teste mit:  docker run --rm hello-world"
}

uninstall_docker() {
  need_root
  log "Docker stoppen und entfernen…"
  systemctl stop docker || true
  apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
  apt-get autoremove -y --purge || true

  log "Datenverzeichnisse entfernen (Images/Container/Volumes)…"
  rm -rf /var/lib/docker /var/lib/containerd || true

  log "APT-Repo & Key entfernen…"
  rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg || true
  apt-get update -y
  log "Uninstall abgeschlossen."
}

test_hello() {
  if ! cmd_exists docker; then err "docker nicht gefunden. Erst 'install' ausführen."; exit 1; fi
  log "Starte Testcontainer…"
  docker run --rm hello-world
  log "OK!"
}

main() {
  case "${1:-}" in
    install) shift; install_docker "$@";;
    uninstall) uninstall_docker;;
    test) test_hello;;
    ""|help|-h|--help)
      cat <<EOF
docker-setup.sh — Debian Installer für Docker Engine + Compose
Usage:
  $0 install [--no-group] [--no-enable] [--rootless]
  $0 test
  $0 uninstall
EOF
      ;;
    *) err "Unbekannter Befehl: $1 (nutze --help)"; exit 1;;
  esac
}
main "$@"
