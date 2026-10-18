#!/usr/bin/env bash
#=====================================================================#
# SETUP: PUT THIS CONFIG ON A COMPUTER
#=====================================================================#
# Run from the cloned repo, as your normal user, on an installed NixOS:
#   ./setup.sh            set up this computer: machines/<name>/ from the
#                         template, users/<you>/ for each person, then a
#                         build that starts on the next boot
#   ./setup.sh add-user   add a person to a machine that is already set up
#   ./setup.sh build [machine]   build a machine set up earlier, for the next boot
# Files in the repo are written and staged with git; anything outside the
# repo (accounts, the build, a reboot) waits for a yes and runs with sudo.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$repo"
nixos_dir=${SETUP_NIXOS_DIR:-/etc/nixos} # where the NixOS installer wrote its config
nix_flags=(--extra-experimental-features "nix-command flakes")
people=() written=() person="" # who is being set up, the files written for them

#--------------------------------------------------------------------#
#-- Output & Prompts
#--------------------------------------------------------------------#
if [[ -t 1 ]]; then bold=$'\e[1m' plain=$'\e[0m'; else bold='' plain=''; fi
say() { printf '%s\n' "$*"; }
section() { printf '\n%s== %s ==%s\n' "$bold" "$*" "$plain"; }
die() {
  printf '\nsetup.sh: %s\n' "$*" >&2
  exit 1
}

#--- ask <var> <question> [default]
ask() {
  local reply
  read -r -p "$2${3:+ [$3]}: " reply || die "no answer, stopping"
  printf -v "$1" '%s' "${reply:-${3:-}}"
}

#--- confirm <question> <y|n default>
confirm() {
  local reply hint="y/N"
  [[ $2 == y ]] && hint="Y/n"
  while true; do
    read -r -p "$1 [$hint] " reply || die "no answer, stopping"
    case ${reply:-$2} in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
    esac
  done
}

#--- pick <result-array> <"Group|setting.path|Label">...: numbered checklist
pick() {
  local -n chosen=$1
  shift
  local i=1 last="" item group rest reply n bad
  for item in "$@"; do
    group=${item%%|*} rest=${item#*|}
    [[ $group != "$last" ]] && printf '  %s\n' "$group" && last=$group
    printf '    %2d) %s\n' "$i" "${rest#*|}"
    i=$((i + 1))
  done
  while true; do
    read -r -p "Numbers to turn on, with spaces between (Enter for none): " reply || die "no answer, stopping"
    chosen=() bad=0
    for n in ${reply//,/ }; do
      if [[ $n =~ ^[0-9]+$ ]] && ((n >= 1 && n < i)); then
        item=${*:n:1}
        chosen+=("${item#*|}") # setting.path|Label
      else
        bad=1
      fi
    done
    ((bad == 0)) && break
    say "Use numbers from 1 to $((i - 1))."
  done
}

#--------------------------------------------------------------------#
#-- Editing settings.nix
#--------------------------------------------------------------------#
#--- A Nix string literal for any text
nix_string() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//'${'/'\${'}
  printf '"%s"' "$s"
}

#--- set_setting <file> <dotted.path> <nix value>: replaces `path = ...;` in a
#--- file laid out like the templates (`name = {` blocks, one setting per line)
set_setting() {
  local tmp
  tmp=$(mktemp)
  if SET_PATH=$2 SET_VALUE=$3 awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    {
      code = $0; sub(/#.*/, "", code); code = trim(code)
      if (code ~ /^[A-Za-z0-9_."-]+[ \t]*=[ \t]*\{$/) {
        name = code; sub(/[ \t]*=.*/, "", name); gsub(/"/, "", name); stack[++depth] = name
      } else if (code ~ /^\};?$/) {
        if (depth > 0) depth--
      } else if (code ~ /^[A-Za-z0-9_."-]+[ \t]*=.*;$/) {
        key = code; sub(/[ \t]*=.*/, "", key); gsub(/"/, "", key)
        full = key
        for (i = depth; i >= 1; i--) full = stack[i] "." full
        if (full == ENVIRON["SET_PATH"]) {
          indent = $0; sub(/[^ \t].*/, "", indent)
          note = ""
          if (index($0, "#")) note = " " substr($0, index($0, "#"))
          print indent key " = " ENVIRON["SET_VALUE"] ";" note
          hits++
          next
        }
      }
      print
    }
    END { exit hits == 1 ? 0 : 1 }
  ' "$1" >"$tmp"; then
    mv "$tmp" "$1"
  else
    rm -f "$tmp"
    die "could not find the setting $2 in $1"
  fi
}

#--- add_line_after <file> <regex> <line>: inserts after the first match
add_line_after() {
  local tmp
  tmp=$(mktemp)
  if AFTER=$2 LINE=$3 awk '
    { print }
    !done && $0 ~ ENVIRON["AFTER"] { print ENVIRON["LINE"]; done = 1 }
    END { exit done ? 0 : 1 }
  ' "$1" >"$tmp"; then
    mv "$tmp" "$1"
  else
    rm -f "$tmp"
    die "no line matching $2 in $1"
  fi
}

#--------------------------------------------------------------------#
#-- What This Computer Has
#--------------------------------------------------------------------#
#--- First quoted value the installer's configuration.nix gives an option
#--- whose name ends in $1 (time.timeZone, i18n.defaultLocale, xkb layout...)
installer_value() {
  [[ -r $nixos_dir/configuration.nix ]] || return 0
  sed -n -E "/^[[:space:]]*[A-Za-z0-9.]*$1[[:space:]]*=[[:space:]]*\"/{s/[^=]*=[[:space:]]*\"([^\"]*)\".*/\1/p;q;}" \
    "$nixos_dir/configuration.nix"
}

#--- Disk-unlock lines that hardware-configuration.nix doesn't carry
installer_boot_lines() {
  [[ -r $nixos_dir/configuration.nix ]] || return 0
  awk '
    /^[[:space:]]*#/ { next }
    !grab && /^[[:space:]]*boot\.(initrd\.luks\.devices|initrd\.secrets|loader\.efi\.efiSysMountPoint)/ { grab = 1; depth = 0 }
    grab {
      print
      depth += gsub(/\{/, "{") - gsub(/\}/, "}")
      if (depth <= 0 && /;[[:space:]]*$/) grab = 0
    }
  ' "$nixos_dir/configuration.nix"
}

#--- 0000:01:00.0 -> PCI:1:0:0, the form hardware.nvidia.prime wants
pci_bus_id() {
  local rest=${1#*:}
  local bus=${rest%%:*} slot=${rest#*:}
  printf 'PCI:%d:%d:%d' "0x$bus" "0x${slot%%.*}" "${slot#*.}"
}

#--- Sets gpu_type, gpu_nvidia_bus, gpu_integrated_bus and gpu_legacy
detect_gpu() {
  local d class vendor device boot found=() primary="" amd="" intel="" nvidia="" nv_device=0
  gpu_type="" gpu_nvidia_bus="" gpu_integrated_bus="" gpu_legacy=false
  for d in /sys/bus/pci/devices/*; do
    class=$(<"$d/class")
    case $class in 0x0300* | 0x0302* | 0x0380*) ;; *) continue ;; esac
    vendor=$(<"$d/vendor") device=$(<"$d/device") boot=0
    [[ -r $d/boot_vga ]] && boot=$(<"$d/boot_vga")
    case $vendor in
      0x1002) amd=${d##*/} found+=(amd) ;;
      0x8086) intel=${d##*/} found+=(intel) ;;
      0x10de) nvidia=${d##*/} nv_device=$device found+=(nvidia) ;;
      *) continue ;;
    esac
    [[ $boot == 1 ]] && primary=${found[-1]}
  done
  ((${#found[@]})) || return 0
  if [[ -n $nvidia ]] && ((nv_device < 0x1e00)); then gpu_legacy=true; fi
  if [[ -n $nvidia && -n $amd$intel ]] && compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then
    # A laptop with two chips: the integrated one runs the screen
    gpu_type="${amd:+amd}${intel:+intel}+nvidia"
    gpu_nvidia_bus=$(pci_bus_id "$nvidia")
    gpu_integrated_bus=$(pci_bus_id "${amd:-$intel}")
  else
    gpu_type=${primary:-${found[0]}}
  fi
}

#--------------------------------------------------------------------#
#-- Choices
#--------------------------------------------------------------------#
#--- Optional apps (users/_template/settings.nix has the rest off too). The
#--- ~/.local/opt bundles aren't offered: the repo can't supply them.
apps=(
  "Browsers|browsers.mullvad|Mullvad Browser"
  "Browsers|browsers.helium|Helium (also opens the Syncthing and Suwayomi pages)"
  "Browsers|browsers.ferdium|Ferdium: web messengers in one window"
  "Terminals|terminals.ghostty|Ghostty"
  "Media|media.spotify|Spotify"
  "Media|media.freetube|FreeTube: YouTube without an account"
  "Media|media.videoTrimmer|Video Trimmer"
  "Media|media.constrict|Constrict: shrink a video to a file size"
  "Media|media.moku|Moku manga and anime reader (built from source, slow)"
  "Media|media.streamlinkTwitchGui|Streamlink Twitch GUI"
  "Media|media.boorusama|Boorusama image board browser"
  "Chat|discord.goofcord|GoofCord: Discord with Vencord (built from source, slow)"
  "Graphics|graphics.blender|Blender"
  "Graphics|graphics.krita|Krita"
  "Graphics|graphics.affinity|Affinity Photo, Designer and Publisher (Wine)"
  "Audio|audio.reaper|REAPER"
  "Audio|audio.guitarix|Guitarix amp simulator"
  "Audio|audio.tone3000|TONE3000 NAM player"
  "Office|office.thunderbird|Thunderbird mail"
  "Office|office.obsidian|Obsidian notes"
  "Office|office.homebank|HomeBank accounts"
  "Security|security.keepassxc|KeePassXC password manager"
  "Security|security.bleachbit|BleachBit disk cleaner"
  "System|system.resources|Resources system monitor"
  "System|scrcpy.enable|scrcpy: show and control an Android phone"
  "Gaming|gaming.heroic|Heroic: Epic, GOG and Amazon games"
  "Gaming|gaming.prismlauncher|Prism Launcher: Minecraft"
  "Gaming|gaming.lutris|Lutris"
  "Gaming|gaming.faugus|Faugus Launcher: Windows games through Proton"
  "Gaming|gaming.twintail|Twintail: gacha games"
  "Gaming|gaming.hytale|Hytale (turns on Flatpak; its launcher is installed by hand)"
  "Gaming|gaming.easyrpg|EasyRPG Player: RPG Maker 2000/2003 games"
  "Gaming|gaming.xsystem4|xsystem4: System 4 engine games"
  "Gaming|gaming.feedback|feedBack guitar rhythm game"
  "Gaming|gaming.rocksmith|Rocksmith 2014 (set up for a BOSS Katana as the input)"
  "Gaming|gaming.r2modman|r2modman mod manager"
  "Gaming|gaming.pathOfBuilding|Path of Building: Path of Exile planner"
  "Gaming|gaming.ludusavi|Ludusavi: daily game save backups"
  "Gaming|discord.arrpc.enable|Show the game you're playing in Discord"
  "AI tools|claude.enable|Claude Code (needs an Anthropic account)"
  "AI tools|opencode.enable|opencode"
  "AI tools|lmstudio.enable|LM Studio: run language models locally"
  "Japanese|japanese.ime|Japanese typing (fcitx5 + Mozc)"
  "Japanese|japanese.vn|Japanese visual novel tools"
)

services=(
  "Services|mullvad.enable|Mullvad VPN (needs a Mullvad account)"
  "Services|syncthing.enable|Syncthing file sync, as the main user"
  "Services|sunshine.enable|Sunshine: stream games to Moonlight on your network"
  "Services|docker.enable|Docker"
  "Services|clamav.enable|ClamAV virus scanner"
  "Services|suwayomi.enable|Suwayomi manga server"
  "Services|ssh.enable|SSH server (key login only)"
)

valid_username() {
  [[ $1 =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && [[ ! $1 =~ ^(root|nobody|greeter)$ ]]
}

#--- Writes users/<name>/settings.nix from the template, asking as it goes
new_user_file() {
  local name=$1 main=$2 file="users/$1/settings.nix" answer picked=() item
  mkdir -p "users/$name"
  cp users/_template/settings.nix "$file"
  sed -i "2s/(TEMPLATE)/(${name^^})/" "$file"

  if [[ $main == 1 ]]; then
    say "$name is this machine's main user, so an admin (sudo, rebuilds)."
  elif ! confirm "Can $name use sudo and change the system (admin)?" n; then
    set_setting "$file" admin false
  fi

  ask answer "Name on $name's git commits (Enter to skip)"
  [[ -n $answer ]] && set_setting "$file" git.name "$(nix_string "$answer")"
  ask answer "Email on $name's git commits (Enter to skip)"
  [[ -n $answer ]] && set_setting "$file" git.email "$(nix_string "$answer")"

  say ""
  say "Everyone starts with Zen, kitty, Helix, Zed, Nautilus, yazi, mpv and Steam."
  say "Extras for $name:"
  pick picked "${apps[@]}"
  for item in "${picked[@]}"; do
    set_setting "$file" "${item%%|*}" true
  done
  say "Wallpapers: still images from the repo, or animated ones from Wallpaper Engine."
  if confirm "Use Wallpaper Engine for $name (needs it bought and installed on Steam)?" n; then
    set_setting "$file" wallpaper '"engine"'
  fi
  written+=("$file")
}

#--- Adds a person to the machine being set up: an existing users/<name>/,
#--- or a new one from the template. Sets `person`.
add_person() {
  local main=$1 default=$2
  while true; do
    ask person "Login name" "$default"
    if ! valid_username "$person"; then
      say "Use lowercase letters, digits, - and _ (start with a letter)."
    elif [[ " ${people[*]} " == *" $person "* ]]; then
      say "$person is already on the list."
    else
      break
    fi
  done
  if [[ -e users/$person/settings.nix ]]; then
    say "users/$person/ already exists; this machine uses it as it is."
  else
    new_user_file "$person" "$main"
  fi
  people+=("$person")
}

#--- Offers to create Linux accounts that don't exist yet, with a password
create_accounts() {
  local u
  for u in "$@"; do
    id -u "$u" >/dev/null 2>&1 && continue
    if confirm "$u has no account on this computer yet. Create it and set a password now?" y; then
      sudo useradd --create-home --no-user-group --gid users "$u"
      sudo passwd "$u"
    else
      say "  Set one later with: sudo passwd $u"
    fi
  done
}

#--- NIX_CONFIG for a build on a system that doesn't have this config's
#--- caches (or flakes) turned on yet. Evaluating it checks the config too.
build_nix_config() {
  local subs keys
  subs=$(nix "${nix_flags[@]}" eval --raw "$repo#nixosConfigurations.$1.config.nix.settings.substituters" --apply toString)
  keys=$(nix "${nix_flags[@]}" eval --raw "$repo#nixosConfigurations.$1.config.nix.settings.trusted-public-keys" --apply toString)
  printf 'experimental-features = nix-command flakes\nextra-substituters = %s\nextra-trusted-public-keys = %s\n' "$subs" "$keys"
}

#--- build_machine <name> <nix config>: builds it as the next boot's default
build_machine() {
  say "The build downloads a lot, and anything missing from the binary caches compiles here; the first one can take an hour or more."
  say "It becomes the default at the next boot; the running desktop is left alone until then."
  sudo env NIX_CONFIG="$2" nixos-rebuild boot --flake "$repo#$1"
}

#--------------------------------------------------------------------#
#-- Modes
#--------------------------------------------------------------------#
new_machine() {
  local name hw state_version tz locale layout keymap wm picked=() item main key boot_lines f

  section "This computer"
  [[ -d /sys/firmware/efi ]] || die "this computer booted without UEFI; the config boots with systemd-boot, which needs it"
  say "A name for this computer in the config (its folder in machines/, and its hostname)."
  while true; do
    ask name "Machine name" "$(hostname)"
    if [[ ! $name =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]]; then
      say "Use lowercase letters, digits and - (no spaces)."
    elif [[ -e machines/$name ]]; then
      say "machines/$name already exists. Pick another name, or run ./setup.sh add-user to add someone to it."
    else
      break
    fi
  done

  state_version=$(installer_value stateVersion)
  [[ -n $state_version ]] || ask state_version "NixOS version this computer was installed with (system.stateVersion, e.g. 26.05)"
  [[ $state_version =~ ^[0-9]{2}\.[0-9]{2}$ ]] || die "\"$state_version\" doesn't look like a NixOS version (e.g. 26.05)"

  section "Language and keyboard"
  say "From the choices made in the installer:"
  tz=$(installer_value timeZone)
  [[ -n $tz ]] || tz=$(timedatectl show --property=Timezone --value 2>/dev/null || true)
  ask tz "Time zone" "${tz:-UTC}"
  locale=$(installer_value defaultLocale)
  ask locale "Language (locale)" "${locale:-en_US.UTF-8}"
  layout=$(installer_value layout)
  ask layout "Keyboard layout" "${layout:-us}"
  keymap=$(installer_value keyMap)
  ask keymap "Keyboard layout on the text console and disk password prompt" "${keymap:-$layout}"

  section "Desktop"
  while true; do
    ask wm "Window manager, for everyone on this computer (niri or hyprland)" niri
    [[ $wm == niri || $wm == hyprland ]] && break
  done
  #--- The template's zen kernel stays: it comes from the binary cache, and
  #--- cachyos would compile on this computer
  say "Kernel: zen. Another one can be picked later with kernel in machines/$name/settings.nix."

  detect_gpu
  if [[ -n $gpu_type ]]; then
    say "Graphics: $gpu_type${gpu_nvidia_bus:+ (NVIDIA at $gpu_nvidia_bus, integrated at $gpu_integrated_bus)}"
    [[ $gpu_legacy == true ]] && say "That NVIDIA card predates Turing, so it gets the older 580 driver."
    confirm "Set up drivers for that?" y || gpu_type=""
  fi

  section "People"
  say "Who will log in here? The first person owns the config and can change the system."
  people=() written=()
  add_person 1 "$USER"
  main=${people[0]}
  while confirm "Add another person?" n; do
    add_person 0 ""
  done
  if [[ " ${people[*]} " != *" $USER "* ]]; then
    say "Note: $USER isn't on the list, so that account goes away after the reboot (its files stay in /home/$USER)."
  fi

  section "Services"
  say "Optional services for the whole computer:"
  pick picked "${services[@]}"

  #--- Write the machine folder
  f=machines/$name/settings.nix
  cp -r machines/_template "machines/$name"
  sed -i "2s/(TEMPLATE)/(${name^^})/" "$f" "machines/$name/default.nix"
  hw=$nixos_dir/hardware-configuration.nix
  if [[ -r $hw ]]; then
    cp "$hw" "machines/$name/hardware/hardware-configuration.nix"
  else
    # sudo only for reading the hardware; the file stays the user's
    # shellcheck disable=SC2024
    nixos-generate-config --show-hardware-config >"machines/$name/hardware/hardware-configuration.nix" 2>/dev/null ||
      sudo nixos-generate-config --show-hardware-config >"machines/$name/hardware/hardware-configuration.nix"
  fi
  boot_lines=$(installer_boot_lines)
  if [[ -n $boot_lines ]]; then
    {
      say "#=====================================================================#"
      say "# BOOT SETTINGS FROM THE NIXOS INSTALLER"
      say "#=====================================================================#"
      say "#- Copied by setup.sh from $nixos_dir/configuration.nix: disk unlocking"
      say "#- that hardware-configuration.nix doesn't carry"
      say "{"
      say "$boot_lines"
      say "}"
    } >"machines/$name/hardware/boot.nix"
    say "Copied disk-unlock settings from the installer into machines/$name/hardware/boot.nix."
  fi

  set_setting "$f" stateVersion "$(nix_string "$state_version")"
  set_setting "$f" timeZone "$(nix_string "$tz")"
  set_setting "$f" locale "$(nix_string "$locale")"
  set_setting "$f" keyboardLayout "$(nix_string "$layout")"
  set_setting "$f" consoleKeyMap "$(nix_string "$keymap")"
  set_setting "$f" windowManager "$(nix_string "$wm")"
  if [[ -n $gpu_type ]]; then
    set_setting "$f" gpu.type "$(nix_string "$gpu_type")"
    set_setting "$f" gpu.nvidiaLegacy "$gpu_legacy"
    set_setting "$f" gpu.nvidiaBusId "$(nix_string "$gpu_nvidia_bus")"
    set_setting "$f" gpu.integratedBusId "$(nix_string "$gpu_integrated_bus")"
  fi
  for ((i = ${#people[@]} - 1; i >= 0; i--)); do
    add_line_after "$f" '^  users = \{' "    ${people[i]} = {};"
  done
  ((${#people[@]} > 1)) && set_setting "$f" mainUser "$(nix_string "$main")"
  [[ $repo == "/home/$main/nixos-config" ]] || set_setting "$f" flakePath "$(nix_string "$repo")"
  for item in "${picked[@]}"; do
    if [[ $item == ssh.enable* ]]; then
      if [[ " ${written[*]} " == *" users/$main/settings.nix "* ]]; then
        ask key "Public SSH key that may log in as $main (ssh-ed25519 ..., Enter to skip SSH)"
      else
        key="" && say "SSH: add a key to ssh.authorizedKeys in users/$main/settings.nix, then turn on ssh.enable."
      fi
      [[ -n $key ]] || continue
      set_setting "users/$main/settings.nix" ssh.authorizedKeys "[$(nix_string "$key")]"
    fi
    set_setting "$f" "${item%%|*}" true
  done
  written=("$f" "${written[@]}")

  git add -- "machines/$name" "${written[@]}"
  section "Written and staged with git"
  printf '  %s\n' "machines/$name/" "${written[@]}"
  if confirm "Open the new settings files in an editor to look them over?" n; then
    "${EDITOR:-nano}" "${written[@]}"
    git add -- "${written[@]}"
  fi

  section "Checking the configuration"
  local nix_config
  nix_config=$(build_nix_config "$name") || die "the configuration has an error (above). Fix the file it names and run: git add -A && ./setup.sh"
  say "It evaluates."

  section "Accounts"
  create_accounts "${people[@]}"

  section "Build"
  if confirm "Build now?" y; then
    build_machine "$name" "$nix_config"
    say ""
    say "Done. After the reboot, log in as $main. Later changes: edit the settings files, then run nixm rebuild."
    say "Commit machines/$name and your users/ folders to keep them with your copy of the repo."
    if confirm "Reboot now?" n; then sudo systemctl reboot; fi
  else
    say "Build it later with: ./setup.sh build $name"
  fi
}

build_later() {
  local machine=${1:-$(hostname)} nix_config
  [[ -e machines/$machine/settings.nix && $machine != _* ]] || die "there is no machines/$machine"
  section "Checking the configuration"
  nix_config=$(build_nix_config "$machine") || die "the configuration has an error (above)"
  section "Build"
  build_machine "$machine" "$nix_config"
  say "Done; it starts at the next boot."
}

add_user() {
  local machine f known=() m main
  for m in machines/*/; do
    m=${m%/} m=${m#machines/}
    [[ $m == _* ]] || known+=("$m")
  done
  ((${#known[@]})) || die "no machines yet; run ./setup.sh first"
  m=$(hostname)
  [[ -d machines/$m ]] || m=${known[0]}
  section "Add a person"
  while true; do
    ask machine "Which machine (${known[*]})" "$m"
    [[ " ${known[*]} " == *" $machine "* ]] && break
  done
  f=machines/$machine/settings.nix

  #--- Two or more users need mainUser written down
  main=$(nix "${nix_flags[@]}" eval --raw "$repo#nixosConfigurations.$machine._module.specialArgs.machine.mainUser") ||
    die "machines/$machine doesn't evaluate; fix the error above first"

  people=() written=()
  mapfile -t people < <(nix "${nix_flags[@]}" eval --json "$repo#nixosConfigurations.$machine._module.specialArgs.machine.users" --apply builtins.attrNames | tr -d '[]"' | tr ',' '\n')
  local before=${#people[@]}
  add_person 0 ""
  ((${#people[@]} > before)) || return 0
  add_line_after "$f" '^  users = \{' "    $person = {};"
  if ! grep -qE '^  mainUser = "' "$f"; then
    if grep -qE '^  mainUser = ' "$f"; then
      set_setting "$f" mainUser "$(nix_string "$main")"
    else
      add_line_after "$f" '^\{' "  mainUser = $(nix_string "$main"); # Owns this config (several users)"$'\n'
    fi
  fi
  git add -- "$f" "${written[@]}"
  section "Written and staged with git"
  printf '  %s\n' "$f" "${written[@]}"

  if [[ $machine == "$(hostname)" ]] && confirm "Rebuild this computer now?" y; then
    sudo nixos-rebuild switch --flake "$repo#$machine"
    [[ $(sudo passwd --status "$person" 2>/dev/null | awk '{print $2}') == P ]] ||
      sudo passwd "$person"
  else
    say "Then on $machine: nixm rebuild, and sudo passwd $person"
  fi
}

#--------------------------------------------------------------------#
#-- Start
#--------------------------------------------------------------------#
case ${1:-} in
  -h | --help)
    sed -n '5,13p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac
((EUID != 0)) || die "run this as your normal user, not with sudo; it asks for sudo when it needs it"
[[ -e /etc/NIXOS ]] || die "this isn't NixOS"
if ! command -v git >/dev/null; then
  say "git isn't installed yet; running this again inside nix-shell -p git."
  exec nix-shell -p git --run "$(printf '%q ' "$0" "$@")"
fi
[[ -e machines/_template/settings.nix && -e users/_template/settings.nix ]] ||
  die "run this from the cloned repo (machines/_template is missing)"

case ${1:-} in
  "") new_machine ;;
  add-user) add_user ;;
  build) build_later "${2:-}" ;;
  *) die "unknown command \"$1\"; try ./setup.sh --help" ;;
esac
