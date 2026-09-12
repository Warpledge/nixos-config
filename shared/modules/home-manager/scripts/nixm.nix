#=====================================================================#
# NIXM - NIX MENU SYSTEM MANAGEMENT SCRIPT
#=====================================================================#
#- A menu-driven helper for NixOS upkeep
#-
#- Run `nixm` for the interactive menu, or `nixm <command>` to skip
#- straight to one. An unknown command prints the full list.
#-
#- Frequent NixOS actions sit at the top level; the rest open as
#- submenus. Esc backs out of a submenu, exits from the top.
#-
#- Credits: original pre-modified script from https://github.com/anotherhadi/nixy
{
  config,
  pkgs,
  username,
  ...
}: let
  #--- Menu colours follow the Stylix base16 scheme
  c = config.lib.stylix.colors;
  rgb = n: "${c."${n}-rgb-r"};${c."${n}-rgb-g"};${c."${n}-rgb-b"}";
  hex = n: "#${c.${n}}";
  nixm =
    pkgs.writeShellScriptBin "nixm"
    # bash
    ''
      function run_cmd() {
        $@
      }

      #--- Serial of one authorised adb device; prompts when several attach
      function adb_target() {
        local devs
        mapfile -t devs < <(${pkgs.android-tools}/bin/adb devices </dev/null | awk 'NR>1 && $2=="device"{print $1}')
        if [[ ''${#devs[@]} -eq 0 ]]; then
          echo "No authorised adb device." >&2
          ${pkgs.android-tools}/bin/adb devices </dev/null | tail -n +2 | grep -q 'unauthorized' \
            && echo "A device is attached but unauthorised - accept the USB debugging prompt." >&2
          return 1
        fi
        if [[ ''${#devs[@]} -eq 1 ]]; then
          printf '%s' "''${devs[0]}"
          return 0
        fi
        printf '%s' "$(printf '%s\n' "''${devs[@]}" | fzf --prompt='device> ')"
      }

      #--- Reads a secure setting, normalising adb's CR and literal "null".
      #--- Every adb call takes </dev/null: adb shell otherwise swallows the
      #--- script's stdin, eating later read prompts.
      function adb_get() {
        local v
        v=$(${pkgs.android-tools}/bin/adb -s "$1" shell settings get secure "$2" </dev/null | tr -d '\r')
        [[ "$v" == "null" ]] && v=""
        printf '%s' "$v"
      }

      #-------------------------------------------------------------------#

      #-- Palette
      #--- Truecolor escapes built from the Stylix base16 scheme, so the
      #--- menu tracks the theme set in shared/modules/theme/stylix.nix.
      E=$'\e'
      R="''${E}[0m"
      C_NIX="''${E}[38;2;${rgb "base0D"}m"
      C_FRM="''${E}[38;2;${rgb "base09"}m"
      C_MON="''${E}[38;2;${rgb "base0B"}m"
      C_NET="''${E}[38;2;${rgb "base0C"}m"
      C_FLA="''${E}[38;2;${rgb "base0A"}m"
      C_TLS="''${E}[38;2;${rgb "base0E"}m"
      C_WRN="''${E}[38;2;${rgb "base08"}m"
      C_AND="''${E}[38;2;${rgb "base07"}m"
      C_DIM="''${E}[38;2;${rgb "base03"}m"

      #-------------------------------------------------------------------#

      #-- Menu Entries
      #--- Format is "command|display". Command goes first so it is the
      #--- field fzf does not append a delimiter to, and so the display
      #--- half can carry ANSI without reaching the command.
      #--- Delimiter is "|", not ";": ANSI escapes contain their own ";",
      #--- and splitting on those cuts the escapes into fragments that fzf
      #--- paints as literal text. --with-nth must stay open-ended too.
      #--- C_WRN marks actions that delete or change what boots.
      BACK="@back|''${C_DIM}󰌍 Back''${R}"

      MENU_MAIN=(
        "@menu:nixos|''${C_NIX}󱄅 NixOS''${R} ''${C_DIM}▸''${R}"
        "@menu:firmware|''${C_FRM}󰚰 Firmware''${R} ''${C_DIM}▸''${R}"
        "@menu:monitor|''${C_MON}󰊡 Monitoring''${R} ''${C_DIM}▸''${R}"
        "@menu:network|''${C_NET}󰤨 Network''${R} ''${C_DIM}▸''${R}"
        "@menu:flatpak|''${C_FLA}󰪮 Flatpak''${R} ''${C_DIM}▸''${R}"
        "@menu:android|''${C_AND}󰀲 Android''${R} ''${C_DIM}▸''${R}"
        "@menu:tools|''${C_TLS}󰘳 Tools''${R} ''${C_DIM}▸''${R}"
      )

      MENU_NIXOS=(
        "nixm rebuild|''${C_NIX}󰑓''${R} Rebuild System"
        "nixm upgrade|''${C_NIX}󰦗''${R} Upgrade System"
        "nixm flake-update|''${C_NIX}󰏢''${R} Flake Update"
        "nixm dryrun|''${C_NIX}󰚀''${R} Dry-run Rebuild"
        "nixm lint|''${C_NIX}󰉨''${R} Lint Config"
        "nixm optimize|''${C_NIX}󰚀''${R} Store Optimize"
        "nixm gc|''${C_WRN}󰭜''${R} Collect Garbage"
        "nixm rollback|''${C_WRN}󰘯''${R} Rollback Generation"
      )

      MENU_FIRMWARE=(
        "nixm firmware-check|''${C_FRM}󰚰''${R} Check Firmware Updates"
        "nixm firmware-devices|''${C_FRM}󰚰''${R} Firmware Devices"
        "nixm firmware-update|''${C_WRN}󰚰''${R} Install Firmware Updates"
      )

      MENU_MONITOR=(
        "nixm monitor|''${C_MON}󰊡''${R} Resource Monitor"
        "nixm disk|''${C_MON}󰉋''${R} Disk Usage"
        "nixm health|''${C_MON}󰌃''${R} Service Status"
        "nixm temps|''${C_MON}󰌡''${R} Temperature Monitor"
      )

      MENU_NETWORK=(
        "nixm network|''${C_NET}󰤨''${R} Network Manager"
        "nixm speedtest|''${C_NET}󰓅''${R} Speed Test"
        "nixm ping|''${C_NET}󰍟''${R} Connection Check"
      )

      MENU_FLATPAK=(
        "nixm flatpak-update|''${C_FLA}󰪮''${R} Update Flatpaks"
        "nixm flatpak-list|''${C_FLA}󰪮''${R} List Flatpaks"
      )

      MENU_TOOLS=(
        "nixm freetube-sync|''${C_TLS}󰗃''${R} FreeTube Sync to Nix"
        "nixm vulkan|''${C_TLS}󰖮''${R} Vulkan Info"
      )

      MENU_ANDROID=(
        "nixm adb-devices|''${C_AND}󰀲''${R} ADB Devices"
        "nixm vpn-list|''${C_AND}󰒃''${R} VPN Allowlist"
        "nixm vpn-edit|''${C_AND}󰏫''${R} Edit VPN Allowlist"
        "nixm debloater|''${C_AND}󰤱''${R} Android Debloater"
      )

      #-------------------------------------------------------------------#

      #-- Menu Engine

      #--- fzf shows field 1, returns the whole row; sed peels off the command
      function pick() {
        local prompt=$1
        shift
        printf '%s\n' "$@" \
          | fzf --ansi --no-mouse --delimiter='|' --with-nth='2..' \
                --prompt="$prompt" \
                --color "fg+:${hex "base05"},bg+:${hex "base02"},prompt:${hex "base0D"},pointer:${hex "base0E"},header:${hex "base03"},hl:${hex "base0E"}:underline,hl+:${hex "base0E"}:underline:reverse" \
          | sed 's/[|].*//'
      }

      #--- Esc backs out of a submenu, exits from the top level
      function ui() {
        local level=main cmd
        while true; do
          case $level in
            main)     cmd=$(pick "nixm> "     "''${MENU_MAIN[@]}") ;;
            nixos)    cmd=$(pick "nixos> "    "''${MENU_NIXOS[@]}" "$BACK") ;;
            firmware) cmd=$(pick "firmware> " "''${MENU_FIRMWARE[@]}" "$BACK") ;;
            monitor)  cmd=$(pick "monitor> "  "''${MENU_MONITOR[@]}" "$BACK") ;;
            network)  cmd=$(pick "network> "  "''${MENU_NETWORK[@]}" "$BACK") ;;
            flatpak)  cmd=$(pick "flatpak> "  "''${MENU_FLATPAK[@]}" "$BACK") ;;
            tools)    cmd=$(pick "tools> "    "''${MENU_TOOLS[@]}" "$BACK") ;;
            android)  cmd=$(pick "android> "  "''${MENU_ANDROID[@]}" "$BACK") ;;
          esac

          case $cmd in
            "")
              [[ $level == main ]] && exit 0
              level=main
              ;;
            @back) level=main ;;
            @menu:*) level=''${cmd#@menu:} ;;
            *)
              run_cmd "$cmd"
              exit 0
              ;;
          esac
        done
      }

      [[ $1 == "" ]] && ui

      # Get current hostname to determine which system to rebuild
      HOSTNAME=$(hostname)
      FLAKE_PATH="/home/${username}/nixos-config"

      case $1 in
        # --- NixOS Operations ---
        rebuild)
          nh os switch "$FLAKE_PATH#nixosConfigurations.$HOSTNAME"
          ;;
        lint)
          echo "=== deadnix: unused arguments ==="
          ${pkgs.deadnix}/bin/deadnix --no-lambda-arg "$FLAKE_PATH" || true
          echo ""
          echo "=== statix: nix antipatterns ==="
          ${pkgs.statix}/bin/statix check "$FLAKE_PATH" || true
          ;;
        upgrade)
          nh os switch --update "$FLAKE_PATH#nixosConfigurations.$HOSTNAME"
          ;;
        flake-update)
          echo "Updating flake inputs..."
          nix flake update --flake "$FLAKE_PATH"
          ;;
        dryrun)
          echo "Running dry-run rebuild (no changes will be made)..."
          nh os switch --dry "$FLAKE_PATH#nixosConfigurations.$HOSTNAME"
          ;;
        gc)
          nh clean all --keep 5
          ;;
        optimize)
          echo "Optimizing Nix store (hardlinking identical files)..."
          nix store optimise
          ;;
        rollback)
          echo "Available generations:"
          sudo nix-env --list-generations -p /nix/var/nix/profiles/system
          read -p "Enter generation number to rollback to: " gen
          sudo nix-env --switch-generation "$gen" -p /nix/var/nix/profiles/system
          sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
          ;;

        # --- FreeTube ---
        freetube-sync)
          MODULE="$FLAKE_PATH/shared/modules/home-manager/programs/media/freetube/subscriptions.nix"
          DB="$HOME/.config/FreeTube/profiles.db"

          if pgrep -x freetube >/dev/null 2>&1; then
            echo "FreeTube is running. Close it first so profiles.db is flushed to disk."
            exit 1
          fi
          [[ -f "$DB" ]] || { echo "No profiles.db found at $DB"; exit 1; }
          [[ -f "$MODULE" ]] || { echo "No module found at $MODULE"; exit 1; }
          ${pkgs.jq}/bin/jq --exit-status . "$DB" >/dev/null 2>&1 || { echo "profiles.db is not valid JSON - refusing to sync."; exit 1; }

          LIVE_IDS=$(mktemp) && DECL_IDS=$(mktemp)
          ${pkgs.jq}/bin/jq -rs '.[0].subscriptions[].id' "$DB" | sort > "$LIVE_IDS"
          grep -oE '"UC[A-Za-z0-9_-]{22}"' "$MODULE" | tr -d '"' | sort > "$DECL_IDS"
          added=$(comm -13 "$DECL_IDS" "$LIVE_IDS" | wc -l)
          removed=$(comm -23 "$DECL_IDS" "$LIVE_IDS" | wc -l)

          echo "Sync FreeTube subscriptions INTO the Nix module."
          echo ""
          echo "  module:   $MODULE"
          echo "  declared: $(wc -l < "$DECL_IDS")   live: $(wc -l < "$LIVE_IDS")"
          echo "  changes:  +$added to add, -$removed to remove"
          echo ""
          echo "This rewrites the declared list in the module to match FreeTube."
          echo "It does NOT modify your FreeTube subscriptions - profiles.db is"
          echo "only read. The module list is overwritten and cannot be undone"
          echo "except through git."
          echo ""

          if [[ "$added" == "0" && "$removed" == "0" ]]; then
            echo "Module already matches FreeTube. Nothing to do."
            rm -f "$LIVE_IDS" "$DECL_IDS"
            exit 0
          fi

          read -p "Proceed? [y/N] " reply
          case "$reply" in
            [yY] | [yY][eE][sS]) ;;
            *)
              echo "Aborted. Nothing was written."
              rm -f "$LIVE_IDS" "$DECL_IDS"
              exit 0
              ;;
          esac

          BODY=$(mktemp)
          ${pkgs.jq}/bin/jq -rs '.[0].subscriptions | sort_by(.name|ascii_downcase) | .[] | "    (sub \"\(.id)\" \"\(.name)\" \"\(.thumbnail)\")"' "$DB" > "$BODY"
          awk -v bodyfile="$BODY" '
            /^  subscriptions = \[$/ { print; while ((getline line < bodyfile) > 0) print line; inlist=1; next }
            inlist && /^  \];$/      { print; inlist=0; next }
            inlist                   { next }
            { print }
          ' "$MODULE" > "$MODULE.new" && mv "$MODULE.new" "$MODULE"
          ${pkgs.alejandra}/bin/alejandra --quiet "$MODULE"
          echo "Wrote $(grep -c '(sub ' "$MODULE") subscriptions to the module."
          echo "Run 'nix flake check' then commit when ready."
          rm -f "$BODY" "$LIVE_IDS" "$DECL_IDS"
          ;;

        # --- System Monitoring ---
        monitor)
          ${pkgs.btop}/bin/btop
          ;;
        disk)
          ${pkgs.ncdu}/bin/ncdu /
          ;;
        health)
          echo "=== Running Services ===" && systemctl list-units --type=service --state=running
          echo ""
          echo "=== Failed Services ===" && systemctl list-units --type=service --state=failed
          ;;
        temps)
          ${pkgs.lm_sensors}/bin/sensors
          ;;

        # --- Network & Connectivity ---
        network)
          ${pkgs.networkmanager}/bin/nmtui
          ;;
        speedtest)
          echo "Running speed test..."
          ${pkgs.speedtest-cli}/bin/speedtest
          ;;
        ping)
          echo "Testing connectivity to 8.8.8.8..."
          ping -c 5 8.8.8.8
          ;;

        # --- Package Management ---
        flatpak-update)
          flatpak update -y
          ;;
        flatpak-list)
          flatpak list --app
          ;;

        # --- Firmware & Updates ---
        firmware-check)
          echo "Checking for firmware updates..."
          ${pkgs.fwupd}/bin/fwupdmgr refresh
          ${pkgs.fwupd}/bin/fwupdmgr get-updates
          ;;
        firmware-update)
          echo "Installing firmware updates..."
          ${pkgs.fwupd}/bin/fwupdmgr refresh
          ${pkgs.fwupd}/bin/fwupdmgr update -y
          ;;
        firmware-devices)
          echo "Devices with available firmware:"
          ${pkgs.fwupd}/bin/fwupdmgr get-devices
          ;;

        # --- Gaming & Performance ---
        vulkan)
          ${pkgs.vulkan-tools}/bin/vulkaninfo | head -50
          ;;

        # --- Android ---
        debloater)
          ${pkgs.universal-android-debloater}/bin/uad-ng
          ;;
        adb-devices)
          ${pkgs.android-tools}/bin/adb devices -l
          ;;
        vpn-list)
          SERIAL=$(adb_target) || exit 1
          APP=$(adb_get "$SERIAL" always_on_vpn_app)
          LOCK=$(adb_get "$SERIAL" always_on_vpn_lockdown)
          RAW=$(adb_get "$SERIAL" always_on_vpn_lockdown_whitelist)

          echo "device        : $SERIAL"
          echo "always-on VPN : $APP"
          echo "lockdown      : $LOCK"
          echo ""

          if [[ -z "$RAW" ]]; then
            echo "Allowlist is empty - every app is confined to the tunnel."
            if [[ "$LOCK" != "1" ]]; then
              echo "Lockdown is off, so nothing is confined either."
            fi
            exit 0
          fi

          INST=$(mktemp)
          ${pkgs.android-tools}/bin/adb -s "$SERIAL" shell 'pm list packages --user 0' </dev/null \
            | tr -d '\r' | sed 's/^package://' | sort > "$INST"

          n=0
          stale=0
          while IFS= read -r p; do
            [[ -z "$p" ]] && continue
            n=$((n + 1))
            if grep -qx "$p" "$INST"; then
              echo "  ok     $p"
            else
              echo "  stale  $p (not installed)"
              stale=$((stale + 1))
            fi
          done < <(printf '%s\n' "$RAW" | tr ',' '\n')
          rm -f "$INST"

          echo ""
          echo "$n entries, $stale stale."
          if [[ "$LOCK" != "1" ]]; then
            echo "Lockdown is off, so the allowlist currently has no effect."
          fi
          ;;
        vpn-edit)
          SERIAL=$(adb_target) || exit 1
          RAW=$(adb_get "$SERIAL" always_on_vpn_lockdown_whitelist)

          INST=$(mktemp) && THIRD=$(mktemp) && TMP=$(mktemp) && CUR=$(mktemp)
          # already-allowlisted entries are filtered out of the suggestions below
          printf '%s\n' "$RAW" | tr ',' '\n' | grep -v '^$' | sort > "$CUR"
          ${pkgs.android-tools}/bin/adb -s "$SERIAL" shell 'pm list packages --user 0' </dev/null \
            | tr -d '\r' | sed 's/^package://' | sort > "$INST"
          ${pkgs.android-tools}/bin/adb -s "$SERIAL" shell 'pm list packages --user 0 -3' </dev/null \
            | tr -d '\r' | sed 's/^package://' | sort > "$THIRD"

          {
            echo "# Apps exempt from VPN lockdown on $SERIAL."
            echo "# They bypass the tunnel and keep network while it is down."
            echo "# Keep this identical to Mullvad's split tunnel list."
            echo "# One package per line. Takes effect only after a reboot."
            echo ""
            [[ -n "$RAW" ]] && printf '%s\n' "$RAW" | tr ',' '\n'
            echo ""
            echo "# ---- not yet allowlisted, uncomment to add ----"
            comm -23 "$THIRD" "$CUR" | sed 's/^/# /'
          } > "$TMP"

          # $EDITOR may carry flags, so test the command word alone; :- only
          # covers an unset value, not one naming a binary that isn't there.
          ED=''${EDITOR:-''${VISUAL:-}}
          if [[ -z "$ED" ]] || ! command -v "''${ED%% *}" >/dev/null 2>&1; then
            [[ -n "$ED" ]] && echo "\$EDITOR (''${ED%% *}) not found, falling back." >&2
            for candidate in micro nano hx helix vim vi; do
              command -v "$candidate" >/dev/null 2>&1 && {
                ED=$candidate
                break
              }
            done
          fi
          if [[ -z "$ED" ]] || ! command -v "''${ED%% *}" >/dev/null 2>&1; then
            echo "No usable editor found. Set \$EDITOR." >&2
            rm -f "$INST" "$THIRD" "$TMP" "$CUR"
            exit 1
          fi

          # An editor that dies must not look like "no edits were made"
          if ! $ED "$TMP"; then
            echo "Editor exited non-zero - nothing was changed." >&2
            rm -f "$INST" "$THIRD" "$TMP" "$CUR"
            exit 1
          fi

          NEW=$(grep -vE '^[[:space:]]*(#|$)' "$TMP" | tr -d '[:blank:]' | sort -u | grep -v '^$' | paste -sd,)
          OLD=$(printf '%s\n' "$RAW" | tr ',' '\n' | grep -v '^$' | sort -u | paste -sd,)

          if [[ "$NEW" == "$OLD" ]]; then
            echo "No change."
            rm -f "$INST" "$THIRD" "$TMP" "$CUR"
            exit 0
          fi

          echo "Changes:"
          comm -13 <(printf '%s\n' "$OLD" | tr ',' '\n' | grep -v '^$') \
                   <(printf '%s\n' "$NEW" | tr ',' '\n' | grep -v '^$') | sed 's/^/  + /'
          comm -23 <(printf '%s\n' "$OLD" | tr ',' '\n' | grep -v '^$') \
                   <(printf '%s\n' "$NEW" | tr ',' '\n' | grep -v '^$') | sed 's/^/  - /'

          warn=0
          while IFS= read -r p; do
            [[ -z "$p" ]] && continue
            grep -qx "$p" "$INST" || {
              echo "  ! $p is not installed on this device"
              warn=1
            }
          done < <(printf '%s\n' "$NEW" | tr ',' '\n')
          [[ $warn -eq 1 ]] && echo "  (uninstalled entries are harmless but do nothing)"

          echo ""
          read -p "Apply to $SERIAL? [y/N] " reply
          case "$reply" in
            [yY] | [yY][eE][sS]) ;;
            *)
              echo "Aborted. Nothing was written."
              rm -f "$INST" "$THIRD" "$TMP" "$CUR"
              exit 0
              ;;
          esac

          if [[ -z "$NEW" ]]; then
            ${pkgs.android-tools}/bin/adb -s "$SERIAL" shell settings delete secure always_on_vpn_lockdown_whitelist </dev/null
          else
            ${pkgs.android-tools}/bin/adb -s "$SERIAL" shell settings put secure always_on_vpn_lockdown_whitelist "$NEW" </dev/null
          fi

          if [[ "$(adb_get "$SERIAL" always_on_vpn_lockdown_whitelist)" == "$NEW" ]]; then
            echo "Written and verified."
          else
            echo "Readback did not match what was written - check the device."
            rm -f "$INST" "$THIRD" "$TMP" "$CUR"
            exit 1
          fi
          rm -f "$INST" "$THIRD" "$TMP" "$CUR"

          echo ""
          echo "The firewall only re-reads this at boot."
          read -p "Reboot $SERIAL now? [y/N] " r2
          case "$r2" in
            [yY] | [yY][eE][sS])
              ${pkgs.android-tools}/bin/adb -s "$SERIAL" reboot
              echo "Rebooting."
              ;;
            *) echo "Not rebooted - the change is inert until you do." ;;
          esac
          ;;


        *)
          echo "Unknown argument: $1"
          echo ""
          echo "Usage: nixm [command]"
          echo ""
          echo "NixOS:"
          echo "  rebuild           - Rebuild system"
          echo "  upgrade           - Rebuild and upgrade system"
          echo "  flake-update      - Update flake inputs"
          echo "  dryrun            - Dry-run rebuild"
          echo "  gc                - Garbage collection"
          echo "  optimize          - Optimize Nix store"
          echo "  rollback          - Rollback to previous generation"
          echo "  lint              - Lint config (deadnix + statix)"
          echo ""
          echo "Firmware:"
          echo "  firmware-check    - Check for firmware updates"
          echo "  firmware-update   - Install firmware updates"
          echo "  firmware-devices  - List firmware-updatable devices"
          echo ""
          echo "Monitoring:"
          echo "  monitor           - Resource monitor (btop)"
          echo "  disk              - Disk usage analysis"
          echo "  health            - Service status"
          echo "  temps             - Temperature monitoring"
          echo ""
          echo "Network:"
          echo "  network           - Network manager"
          echo "  speedtest         - Internet speed test"
          echo "  ping              - Connection check"
          echo ""
          echo "Flatpak:"
          echo "  flatpak-update    - Update Flatpaks"
          echo "  flatpak-list      - List installed Flatpaks"
          echo ""
          echo "Tools:"
          echo "  freetube-sync     - Sync FreeTube subscriptions into Nix"
          echo "  vulkan            - Vulkan capabilities"
          echo ""
          echo "Android:"
          echo "  adb-devices       - List attached adb devices"
          echo "  vpn-list          - Show the VPN lockdown allowlist"
          echo "  vpn-edit          - Edit the VPN lockdown allowlist"
          echo "  debloater         - Android Debloater Next Gen"
          ;;
      esac
    '';
in {
  home.packages = [nixm];

  programs.zsh.shellAliases = {
    #--- Shorthand alias for nixm script
    n = "nixm";
  };
}
