#=====================================================================#
# NIXM - NIX MENU SYSTEM MANAGEMENT SCRIPT
#=====================================================================#
#- A menu-driven helper for NixOS upkeep
#-
#- Run `nixm` for the interactive menu, or `nixm <command>` to skip
#- straight to one. An unknown command prints the full list.
#-
#- Credits: original pre-modified script from https://github.com/anotherhadi/nixy
{
  pkgs,
  username,
  ...
}: let
  nixm =
    pkgs.writeShellScriptBin "nixm"
    # bash
    ''
      function exec() {
        $@
      }

      function ui(){
        DEFAULT_ICON="󰘳"

        # "icon;name;command"[]
        apps=(
          ";󱄅 ==== NixOS Operations ==== 󱄅;"
          "󰑓;Rebuild System;nixm rebuild"
          "󰦗;Upgrade System;nixm upgrade"
          "󰏢;Flake Update;nixm flake-update"
          "󰚀;Dry-run Rebuild;nixm dryrun"
          "󰭜;Collect Garbage;nixm gc"
          "󰚀;Store Optimize;nixm optimize"
          "󰘯;Rollback Generation;nixm rollback"
          "󰉨;Lint Config;nixm lint"

          "; ==== Firmware ==== ;"
          "󰚰;Check Firmware Updates;nixm firmware-check"
          "󰚰;Install Firmware Updates;nixm firmware-update"
          "󰚰;Firmware Devices;nixm firmware-devices"

          "; ==== System Monitoring ==== ;"
          "󰊡;Resource Monitor;nixm monitor"
          "󰉋;Disk Usage;nixm disk"
          "󰌃;Service Status;nixm health"
          "󰌡;Temperature Monitor;nixm temps"

          "; ==== Network ==== ;"
          "󰤨;Network Manager;nixm network"
          "󰓅;Speed Test;nixm speedtest"
          "󰍟;Connection Check;nixm ping"

          "; ==== Flatpak ==== ;"
          "󰪮;Update Flatpaks;nixm flatpak-update"
          "󰪮;List Flatpaks;nixm flatpak-list"

          "; ==== AMD GPU ==== ;"
          "󰖮;Vulkan Info;nixm vulkan"

          "; ==== FreeTube ==== ;"
          "󰗃;Sync Subscriptions to Nix;nixm freetube-sync"

          "; ==== Android ==== ;"
          "󰤱;Android Debloater;nixm debloater"
        )

        # Apply default icons if empty and mark categories:
        for i in "''${!apps[@]}"; do
          IFS=';' read -r icon name command <<< "''${apps[$i]}"
          if [[ "$name" == *"===="* ]]; then
            apps[$i]="$icon;$name;CATEGORY"
          elif [[ -z "$icon" ]]; then
            apps[$i]="$DEFAULT_ICON;$name;$command"
          fi
        done

        # Display all items but make categories non-selectable
        fzf_result=$(printf "%s\n" "''${apps[@]}" | awk -F ';' '{
          if ($3 == "CATEGORY")
            print "\033[1;35m" $1 " " $2 "\033[0m"
          else
            print $1 " " $2
        }' | fzf --ansi --no-mouse --color 'hl:-1:underline,hl+:-1:underline:reverse' --header-lines=1)

        [[ -z $fzf_result ]] && exit 0
        fzf_result=''${fzf_result/ /;}
        line=$(printf "%s\n" "''${apps[@]}" | grep "$fzf_result")
        command=$(echo "$line" | sed 's/^[^;]*;//;s/^[^;]*;//')

        if [[ "$command" != "CATEGORY" ]]; then
          exec "$command"
        else
          echo "Categories are not selectable. Please choose a specific action."
        fi
        exit 0
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

        # --- Mobile Devices ---
        debloater)
          ${pkgs.universal-android-debloater}/bin/uad-ng
          ;;

        *)
          echo "Unknown argument: $1"
          echo ""
          echo "Usage: nixm [command]"
          echo ""
          echo "Commands:"
          echo "  rebuild           - Rebuild system"
          echo "  lint              - Lint config (deadnix + statix)"
          echo "  upgrade           - Rebuild and upgrade system"
          echo "  flake-update      - Update flake inputs"
          echo "  dryrun            - Dry-run rebuild"
          echo "  gc                - Garbage collection"
          echo "  optimize          - Optimize Nix store"
          echo "  rollback          - Rollback to previous generation"
          echo "  monitor           - Resource monitor (btop)"
          echo "  disk              - Disk usage analysis"
          echo "  health            - Service status"
          echo "  temps             - Temperature monitoring"
          echo "  network           - Network manager"
          echo "  speedtest         - Internet speed test"
          echo "  ping              - Connection check"
          echo "  flatpak-update    - Update Flatpaks"
          echo "  flatpak-list      - List installed Flatpaks"
          echo "  firmware-check    - Check for firmware updates"
          echo "  firmware-update   - Install firmware updates"
          echo "  firmware-devices  - List firmware-updatable devices"
          echo "  vulkan            - Vulkan capabilities"
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
