#!/usr/bin/env bash
# Instala a barra cadrocbar e configura para rodar via Hyprland.
# Uso: bash install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

log()  { printf '\033[1;36m[cadrocbar]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[cadrocbar]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[cadrocbar]\033[0m %s\n' "$*" >&2; }

deps=(quickshell curl jq python3 wpctl brightnessctl nmcli bluetoothctl)
missing=()
for d in "${deps[@]}"; do
	command -v "$d" >/dev/null 2>&1 || missing+=("$d")
done

echo
log "cadrocbar"
log "  repo: $REPO_DIR"
echo

if (( ${#missing[@]} > 0 )); then
	warn "dependências ausentes (instale antes de continuar): ${missing[*]}"
else
	ok "dependências principais encontradas"
fi

command -v hyprctl >/dev/null 2>&1 \
	&& ok "Hyprland detectado" \
	|| warn "Hyprland não detectado (a barra é feita para Hyprland)"

if command -v cliphist >/dev/null 2>&1; then
	ok "cliphist detectado (launcher de área de transferência)"
else
	warn "cliphist ausente: o modo clipboard do launcher ficará desabilitado"
fi

command -v qrencode >/dev/null 2>&1 \
	&& ok "qrencode detectado (QR de Wi-Fi)" \
	|| warn "qrencode ausente: QR de Wi-Fi indisponível"

# Configuração opcional por usuário
mkdir -p "$CONFIG_HOME/cadrocbar" "$STATE_HOME/quickshell"

if [[ ! -f "$CONFIG_HOME/cadrocbar/weather.location" ]]; then
	: > "$CONFIG_HOME/cadrocbar/weather.location"
	warn "crie $CONFIG_HOME/cadrocbar/weather.location com sua cidade (ex.: Lisbon) para o clima; vazio = auto por IP"
fi

if [[ ! -f "$CONFIG_HOME/cadrocbar/avatar.png" ]]; then
	warn "avatar opcional: coloque uma foto em $CONFIG_HOME/cadrocbar/avatar.png"
fi

# Scripts dos módulos ficam dentro do repo (via Theme.binDir)
chmod +x "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/scripts/*.py 2>/dev/null || true

echo
log "Para iniciar a barra (Hyprland):"
log "  quickshell --path $REPO_DIR/quickshell/"
echo
log "Adicione no autostart do Hyprland:"
log "  quickshell --path $REPO_DIR/quickshell/"
echo
ok "pronto. Configure CADROCBAR_WEATHER_LOCATION e CADROCBAR_TERMINAL conforme necessário."