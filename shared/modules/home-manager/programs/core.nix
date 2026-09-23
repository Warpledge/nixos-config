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
  home.packages = with pkgs; [
    #--- Utils
    inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
    poppler-utils # PDF rendering library
    # localsend

    #--- Archives
    file-roller
    zip
    unzip
    unrar
    _7zz-rar

    #--- Gnome
    gnome-calculator
    baobab
    gnome-text-editor
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
    yt-dlp
    zenity

    #--- System Tools
    pavucontrol
    amdgpu_top
    psmisc
    lm_sensors
    psutils
    playerctl
    file
    lsof
    ps_mem
    pciutils

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
