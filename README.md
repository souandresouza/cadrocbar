# cadrocbar

Barra e widgets para **Hyprland**, construídos com [QuickShell](https://quickshell.outfoxxed.me/).
Tema dinâmico a partir do [pywal](https://github.com/dylanaraps/pywal) (fallback embutido), fontes e glyphs da Nerd Font.

## Requisitos

- Hyprland (0.4x+) com socket para IPC (`hyprctl`)
- [QuickShell](https://quickshell.outfoxxed.me/) (≥ 0.1.0)
- Nerd Font (padrão: `JetBrainsMono Nerd Font`) — altere em `quickshell/Common/Theme.qml`
- `curl`, `jq`, `python3`
- PipeWire/WirePlumber (`wpctl`) — volume
- `brightnessctl` — brilho
- opcionais:
  - `swaync` — ícone na barra abre/alterna o painel de notificações (`swaync-client -t`)
  - `wl-clipboard` (`wl-copy`) — copia o resultado da calculadora do launcher
  - `swaylock` — fallback do lock screen

## Instalação

```bash
git clone https://github.com/souandresouza/cadrocbar.git ~/cadrocbar
bash ~/cadrocbar/install.sh
```

O `install.sh` verifica dependências e cria a pasta de configuração por usuário.

## Iniciar

```bash
quickshell -c cadrocbar
# ou, direto do repo:
quickshell --path ~/cadrocbar/quickshell/
```

Adicione no autostart do Hyprland (ex.: em `hyprland.conf` ou um `.lua` com `hl.exec_cmd`). **Use apenas uma** das formas acima — duas instâncias simultâneas geram barras duplicadas:

```lua
hl.exec_cmd("quickshell -c cadrocbar")
```

## Módulos ativos

| Seção | Módulos |
| --- | --- |
| Esquerda | Workspaces (número da ativa), FocusedWindow, Media |
| Centro | Clock |
| Direita | IdleInhibitor, Audio, Backlight, Swaync, PowerMenu, Lock, Battery |

Clicar no ícone do IdleInhibitor alterna a inibição de suspensão (ícone de olho aberto/fechado).
O ícone do Swaync exige que o daemon `swaync` esteja rodando.

## Launcher

`Super+Space` abre o launcher (via IPC). Além de apps, ele entende:

- **calculadora**: `2+2*3` → `8`, `sqrt(16)+2` → `6`, `pi*2` → `6.283185` (resultado vai para `wl-copy`)
- **busca web** (prefixo + espaço): `g foo`, `yt teste`, `w hyprland`, `gh cadroc`, `ddg linux`
- **comando**: `> ls` executa no terminal definido por `CADROCBAR_TERMINAL`

## Configuração

| Item | Como configurar |
| --- | --- |
| Avatar no lock | imagem em `~/.config/cadrocbar/avatar.png` (opcional, oculta se ausente) |
| Terminal p/ apps | env `CADROCBAR_TERMINAL` (padrão `kitty`) |
| Papel de parede no lock | `~/.cache/current_wallpaper.png` |
| Cores | geradas do pywal (`~/.cache/wal/colors.css`); se ausente, usa a paleta padrão do `Theme.qml` |

## Binds (IPC)

O bar expõe chamadas IPC via `qs` (o CLI do QuickShell):

```bash
qs -c cadrocbar ipc call launcher toggleApps
qs -c cadrocbar ipc call launcher isOpen
qs -c cadrocbar ipc call launcher search '2+2*3'

qs -c cadrocbar ipc call lock toggle
qs -c cadrocbar ipc call lock isLocked

# paleta (chamado pelo script de wallpaper após o ruwall/pywal gerar ~/.cache/wal)
qs -c cadrocbar ipc call theme reload
qs -c cadrocbar ipc call theme accent   # debug: cor de destaque atual
```

A barra lê `~/.cache/wal/colors.css` no startup, mas **não** detecta mudanças sozinha.
Ao trocar o wallpaper, chame `theme reload` (via `run-scripts.sh` ou do próprio
comando do gerador de paleta) para atualizar cores da barra e do launcher sem
reiniciar o QuickShell.

Exemplo em `binds.lua` do Hyprland:

```lua
local ipc = "qs -c cadrocbar ipc call"
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(ipc .. " launcher toggleApps"), { description = "app launcher" })
hl.bind("SUPER + L",     hl.dsp.exec_cmd(ipc .. " lock toggle"),           { description = "lock screen" })
```

## Estrutura

```
cadrocbar/
├── install.sh            # verificação de dependências e setup
├── quickshell/           # config do QuickShell (Bar.qml, Modules/, Services/, Popouts/)
│   ├── Bar.qml           # barra principal (escolha os módulos aqui)
│   ├── Modules/          # Audio, Backlight, Battery, Clock, FocusedWindow,
│   │                     # IdleInhibitor, Lock, Media, PowerMenu, Swaync, Workspaces
│   ├── Services/         # Audio, Backlight, IdleInhibitor, Launcher, Lock, Mpris, Popup
│   ├── Popouts/          # calendar, mídia, power menu
│   ├── Widgets/          # IconText, ModuleButton
│   └── Common/           # Theme, PopoutBase, MathEval (parser da calculadora)
└── scripts/              # backlight.sh, launcher.py, mpris.py
```

Os scripts são localizados dinamicamente (relativos ao diretório do QuickShell), então o repo pode ser clonado em qualquer caminho.

## Customizar módulos

Edite `quickshell/Bar.qml` — a seção direita (`rightSection`) lista os módulos ativos. Para adicionar/remover, basta comentar/descomentar a linha do módulo correspondente:

```qml
IdleInhibitor {}
Audio {}
Backlight {}
Swaync {}
PowerMenu { popup: powerMenuPopup }
Lock {}
Battery {}
```

Para manter o atalho `Super+Space` funcionando sem exibir o ícone do launcher, preserve em `Bar.qml`:

```qml
property var launcherRef: LauncherService
```

Sem essa referência o singleton não é instanciado e o IPC do launcher responde `Target not found`.
