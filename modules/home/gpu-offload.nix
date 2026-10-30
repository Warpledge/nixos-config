#=====================================================================#
# RUN ON THE DGPU (gpuOffload IN THE USER'S SETTINGS)
#=====================================================================#
#- Copies each listed app's .desktop entry into ~/.local/share/applications
#- with its Exec lines run through nvidia-offload. Copies carry
#- X-Omni-Offload=true; only those are ever replaced or removed.
{
  lib,
  pkgs,
  user,
  ...
}: {
  home.activation.gpuOffload = lib.hm.dag.entryAfter ["linkGeneration"] ''
    apps="$HOME/.local/share/applications"
    wanted=" ${lib.concatStringsSep " " user.gpuOffload} "
    sources=("$HOME/.nix-profile/share/applications" "/etc/profiles/per-user/$USER/share/applications"
      "/run/current-system/sw/share/applications"
      "$HOME/.local/share/flatpak/exports/share/applications"
      "/var/lib/flatpak/exports/share/applications")

    #--- Drop copies no longer listed, or whose app is gone
    for f in "$apps"/*.desktop; do
      [ -f "$f" ] && grep -qx 'X-Omni-Offload=true' "$f" || continue
      id=$(basename "$f")
      if [[ "$wanted" != *" $id "* ]]; then run rm "$f"; fi
    done

    for id in $wanted; do
      src=""
      for d in "''${sources[@]}"; do
        if [ -f "$d/$id" ]; then src="$d/$id"; break; fi
      done
      dest="$apps/$id"
      if [ -z "$src" ]; then
        [ -f "$dest" ] && grep -qx 'X-Omni-Offload=true' "$dest" && run rm "$dest"
        continue
      fi
      #--- Never replace an entry the user made themselves
      if [ -f "$dest" ] && ! grep -qx 'X-Omni-Offload=true' "$dest"; then continue; fi
      run mkdir -p "$apps"
      # DBusActivatable entries are started over D-Bus, skipping Exec
      tmp=$(mktemp)
      ${lib.getExe pkgs.gnused} -E -e '/^DBusActivatable=/d' \
        -e '/^Exec=nvidia-offload /!s/^Exec=/Exec=nvidia-offload /' \
        -e '/^\[Desktop Entry\]$/a X-Omni-Offload=true' "$src" > "$tmp"
      run install -m 644 "$tmp" "$dest"
      rm -f "$tmp"
    done
  '';
}
