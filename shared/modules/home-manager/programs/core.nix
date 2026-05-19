#=====================================================================#
# PACKAGES CONFIGURATION
#====================================================================#
{
  pkgs,
  inputs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  #- Packages module: Single-purpose utilities, GNOME applications, and dependencies
  #- Full applications with extensive configuration should have their own modules in programs/
  #- Examples: Browsers have programs/browsers/, Editors have programs/editors/, etc.
  #- This module consolidates lightweight tools and development dependencies
  #- Organized by category: Apps, Utils, AI, GNOME, CLI, System Tools, Archives, Dev, Fun

  home.packages = with pkgs; [
    #--- Apps
    thunderbird
    obsidian
    faugus-launcher

    #--- Utils
    inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
    bleachbit
    gearlever
    # localsend
    # easyrpg-player

    #--- Gnome
    file-roller
    gnome-calculator
    baobab
    gnome-text-editor
    (celluloid.override {youtubeSupport = true;})
    loupe
    evince
    resources

    #--- CLI
    deadnix
    statix
    gtrash
    ttyper
    onefetch
    lazygit
    man-pages
    tdf
    tldr
    figlet
    ani-cli
    zenity

    #--- System Tools
    amdgpu_top
    psmisc
    lm_sensors
    psutils
    playerctl
    file
    lsof
    ps_mem
    pciutils

    #--- Archives
    zip
    unzip
    unrar
    _7zz-rar

    #--- Dev
    go
    gdb
    gnumake
    nodejs
    jq
    glibc
    ilspycmd

    #--- Cool
    cmatrix

    #--- Qt Theme Support
    kdePackages.qtstyleplugin-kvantum
    catppuccin-kvantum
    qt6.qt5compat
  ];

  #--- Options
  programs = {
    dircolors = {
      enable = true;
    };
  };

  #--- Disable manuals - nmd fails to build often
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
