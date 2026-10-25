#=====================================================================#
# KYLERJ'S APPS
#=====================================================================#
#- Apps with no switch in users/_template/settings.nix. Emulators, the Epic
#- launcher and other AppImages are kept by hand (Gear Lever), RetroDECK
#- through Flatpak.
{
  lib,
  pkgs,
  ...
}: let
  #--- nixpkgs' binary wrapper takes each makeWrapperArgs entry as one argument,
  #--- so its "${gappsWrapperArgs[@]}" and "--prefix PATH : ..." fail the build
  gearlever = pkgs.gearlever.overrideAttrs (old: {
    makeWrapperArgs = [];
    preFixup = ''
      makeWrapperArgs+=("''${gappsWrapperArgs[@]}" ${lib.concatStringsSep " " (lib.tail old.makeWrapperArgs)})
    '';
  });
in {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    #--- Browsers
    vivaldi
    chromium

    #--- Editors
    kdePackages.kate

    #--- Chat
    discord
    vesktop

    #--- Games & Game Tools
    osu-lazer-bin
    shipwright # Ship of Harkinian
    _2ship2harkinian
    archipelago
    gale # Thunderstore mod manager
    protonup-qt
    lsfg-vk
    lsfg-vk-ui
    bottles

    #--- Creative & Office
    kdePackages.kdenlive
    godot
    onlyoffice-desktopeditors
    carla

    #--- System
    gearlever # AppImage manager
    kdePackages.partitionmanager
    kdePackages.filelight
    qpwgraph
  ];

  #--- Easy Effects runs in the background from login
  services.easyeffects.enable = true;

  #--------------------------------------------------------------------#
  #-- Default Browser
  #--------------------------------------------------------------------#
  #--- Vivaldi isn't one of lib/default-apps.nix's choices, so it's set here
  xdg.mimeApps.defaultApplications = lib.genAttrs [
    "text/html"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ] (_: lib.mkForce ["vivaldi-stable.desktop"]);
}
