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
        "󰮯  GregTech: New Horizons 2.9.0" \
        "󰮯  GregTech Odyssey 0.6.0-dev27" \
        "󰮯  TerraFirmaGreg Modern 0.12.5" \
      | ${pkgs.fzf}/bin/fzf \
          --prompt="  Select Server > " \
          --height=7 \
          --border \
          --no-info)

      [[ -z "$choice" ]] && exit 0

      case "$choice" in
        *"New Horizons"*)
          exec gtnh
          ;;
        *"Odyssey"*)
          exec gtoserver
          ;;
        *"TerraFirmaGreg"*)
          exec tfg
          ;;
      esac
    '';
in {
  home.packages = [mcservers];
}
