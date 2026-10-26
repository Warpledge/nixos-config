#=====================================================================#
# UNREAL ENGINE
#=====================================================================#
#- Epic's prebuilt Linux editor, extracted by hand to ~/Games/UnrealEngine
#- and kept out of git. It runs in Steam's FHS environment plus nss/nspr,
#- which that environment lacks.
{pkgs, ...}: let
  engineDir = "$HOME/Games/UnrealEngine/Linux_Unreal_Engine_5.8.4";
  fhs = (pkgs.steam.override {extraPkgs = p: [p.nss p.nspr];}).run;
  unreal-editor = pkgs.writeShellScriptBin "unreal-editor" ''
    exec ${fhs}/bin/steam-run "${engineDir}/Engine/Binaries/Linux/UnrealEditor" "$@"
  '';
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [unreal-editor];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#

  xdg.desktopEntries.unreal-editor = {
    name = "Unreal Editor";
    comment = "Unreal Engine 5.8 editor";
    exec = "unreal-editor %U";
    # The engine's own logo; the folder isn't in the store, so the path is literal
    icon = "/home/kylerj/Games/UnrealEngine/Linux_Unreal_Engine_5.8.4/Engine/Plugins/VirtualProduction/Switchboard/Source/Switchboard/switchboard/ui/images/unreal_logo.png";
    terminal = false;
    categories = ["Development" "IDE"];
  };
}
