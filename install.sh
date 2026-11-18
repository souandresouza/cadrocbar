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

deps=(quickshell curl jq python3 wpctl brightnessctl)
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

if command -v swaync >/dev/null 2>&1; then
	ok "swaync detectado (ícone de notificações na barra)"
else
	warn "swaync ausente: o ícone de notificações ficará inativo"
fi

if command -v wl-copy >/dev/null 2>&1; then
	ok "wl-copy detectado (calculadora do launcher)"
else
	warn "wl-copy ausente: a calculadora do launcher não poderá copiar o resultado"
fi

command -v swaylock >/dev/null 2>&1 \
	&& ok "swaylock detectado" \
	|| warn "swaylock ausente: fallback do lock screen indisponível"

# Configuração opcional por usuário
mkdir -p "$CONFIG_HOME/cadrocbar" "$STATE_HOME/quickshell"

if [[ ! -f "$CONFIG_HOME/cadrocbar/avatar.png" ]]; then
	warn "avatar opcional: coloque uma foto em $CONFIG_HOME/cadrocbar/avatar.png"
fi

# Scripts dos módulos ficam dentro do repo (via Theme.binDir)
chmod +x "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/scripts/*.py 2>/dev/null || true

echo
log "Para iniciar a barra (Hyprland):"
log "  quickshell --path $REPO_DIR/quickshell/"
echo
log "Adicione no autostart do Hyprland (use APENAS UMA instância):"
log "  quickshell --path $REPO_DIR/quickshell/"
echo
ok "pronto. Configure CADROCBAR_TERMINAL conforme necessário."
