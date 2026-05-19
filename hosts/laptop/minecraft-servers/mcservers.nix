#=====================================================================#
# MCSERVERS - MINECRAFT SERVER PICKER
#=====================================================================#
#- fzf-based picker to start any configured Minecraft server.
#-
#- Commands:
#-   mcservers — Open server picker and launch selected server
{pkgs, ...}: let
  mcservers =
    pkgs.writeShellScriptBin "mcservers"
    # bash
    ''
      choice=$(printf "%s\n" \
        "󰮯  GregTech: New Horizons 2.8.4" \
        "󰮯  TerraFirmaGreg Modern 0.12.5" \
      | ${pkgs.fzf}/bin/fzf \
          --prompt="  Select Server > " \
          --height=6 \
          --border \
          --no-info)

      [[ -z "$choice" ]] && exit 0

      case "$choice" in
        *"GregTech"*)
          exec gtnh
          ;;
        *"TerraFirmaGreg"*)
          exec tfg
          ;;
      esac
    '';
in {
  home.packages = [mcservers];
}
