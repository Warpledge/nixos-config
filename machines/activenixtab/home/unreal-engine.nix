#=====================================================================#
# UNREAL ENGINE
#=====================================================================#
#- Epic's prebuilt Linux editor, extracted by hand to ~/Games/UnrealEngine
#- and kept out of git.
#- The editor links against the Chromium/CEF set (atk, nss, gbm, ...). The host
#- does not provide those and Steam's FHS environment stopped carrying them, so
#- they are declared here instead of borrowed from steam-run.
{pkgs, ...}: let
  engineDir = "$HOME/Games/UnrealEngine/Linux_Unreal_Engine_5.8.4";

  unrealFHS = pkgs.buildFHSEnv {
    name = "unreal-fhs";
    targetPkgs = p:
      with p; [
        alsa-lib
        at-spi2-core
        cairo
        dbus
        expat
        glib
        nspr
        nss
        pango
        libdrm
        mesa
        vulkan-loader
        libGL
        libgbm
        libx11
        libxcb
        libXcomposite
        libXdamage
        libxext
        libxfixes
        libxrandr
        libxkbcommon
        bash
        coreutils
        findutils
        which
        python3
      ];
    extraBinds = ["/home" "/run/opengl-driver"];
    runScript = "bash";
  };

  unreal-editor = pkgs.writeShellScriptBin "unreal-editor" ''
    cmd=$(printf '%q ' "${engineDir}/Engine/Binaries/Linux/UnrealEditor" "$@")
    exec ${unrealFHS}/bin/unreal-fhs -c "$cmd"
  '';
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  #- unreal-fhs is exposed so a project can run UnrealEditor-Cmd or Build.sh
  #- inside it: `unreal-fhs -c "<command>"`
  home.packages = [unreal-editor unrealFHS];

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
