# cadrocbar

Barra e widgets para **Hyprland**, construídos com [QuickShell](https://quickshell.outfoxxed.me/).
Tema dinâmico a partir do [pywal](https://github.com/dylanaraps/pywal) (fallback embutido), fontes e glyphs da Nerd Font.

## Requisitos

- Hyprland (0.4x+) com socket para IPC (`hyprctl`)
- [QuickShell](https://quickshell.outfoxxed.me/) (≥ 0.1.0)
- Nerd Font (padrão: `JetBrainsMono Nerd Font`) — altere em `quickshell/Common/Theme.qml`
- `curl`, `jq`, `python3`
- PipeWire/WirePlumber (`wpctl`)
- `brightnessctl` (brilho)
- NetworkManager (`nmcli`)
- BlueZ (`bluetoothctl`)
- opcionais:
  - `cliphist` + `wl-clipboard` — modo clipboard do launcher
  - `qrencode` — QR de Wi-Fi no popup de rede
  - `swaylock` — fallback do lock screen

## Instalação

```bash
git clone https://github.com/<seu-usuario>/cadrocbar.git ~/cadrocbar
bash ~/cadrocbar/install.sh
```

O `install.sh` verifica dependências e cria a pasta de configuração por usuário.

## Iniciar

```bash
quickshell --path ~/cadrocbar/quickshell/
```

Adicione no autostart do Hyprland (ex.: em `hyprland.conf` ou um `.lua` com `hl.exec_cmd`):

```
quickshell --path ~/cadrocbar/quickshell/
```

## Configuração

| Item | Como configurar |
| --- | --- |
| Cidade do clima | arquivo `~/.config/cadrocbar/weather.location` (uma linha, ex.: `Lisbon`) ou env `CADROCBAR_WEATHER_LOCATION`. Vazio = localização automática do wttr.in |
| Avatar no lock | imagem em `~/.config/cadrocbar/avatar.png` (opcional, oculta se ausente) |
| Terminal p/ apps | env `CADROCBAR_TERMINAL` (padrão `kitty`) |
| Papel de parede no lock | `~/.cache/current_wallpaper.png` |
| Cores | geradas do pywal (`~/.cache/wal/colors.css`); se ausente, usa a paleta padrão do `Theme.qml` |

## Binds (IPC)

O bar expõe chamadas IPC via `qsc` (o CLI do QuickShell):

```bash
# launcher de apps / clipboard
qsc -s cadrocbar ipc call launcher toggleApps
qsc -s cadrocbar ipc call launcher toggleClipboard

# lock
qsc -s cadrocbar ipc call lock toggle
qsc -s cadrocbar ipc call lock isLocked
```

Exemplo em `binds.lua` do Hyprland:

```lua
local ipc = "qsc -s cadrocbar ipc call"
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(ipc .. " launcher toggleApps"), { description = "app launcher" })
hl.bind("SUPER + L",     hl.dsp.exec_cmd(ipc .. " lock toggle"),           { description = "lock screen" })
```

## Estrutura

```
cadrocbar/
├── install.sh            # verificação de dependências e setup
├── quickshell/           # config do QuickShell (Bar.qml, Modules/, Services/, Popouts/)
│   ├── Bar.qml           # barra principal (escolha os módulos aqui)
│   ├── Modules/          # Launcher, Workspaces, Clock, Weather, Audio, ...
│   ├── Services/         # serviços (Wi-Fi, áudio, MPRIS, notificações, lock...)
│   ├── Popouts/          # popups (calendário, mídia, power menu...)
│   └── Common/Theme.qml  # paleta, medidas, fontes
└── scripts/              # scripts auxiliares (network, wifi, weather, sysinfo...)
```

Os scripts são localizados dinamicamente (relativos ao diretório do QuickShell), então o repo pode ser clonado em qualquer caminho.

## Customizar módulos

Edite `quickshell/Bar.qml` — a seção direita (`rightSection`) lista os módulos ativos. Para adicionar/remover, basta comentar/descomentar a linha do módulo correspondente:

```qml
Weather {}
Audio {}
Backlight {}
PowerMenu { popup: powerMenuPopup }
Lock {}
PowerProfile {}
Battery {}
```

Módulos e popups opcionais também existem em `Modules/` e `Popouts/` (ex.: `Network`, `Bluetooth`, `Cpu`, `Memory`, `Temperature`, `Notifications`, `ControlCenter`).