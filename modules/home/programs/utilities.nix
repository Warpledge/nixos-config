#=====================================================================#
# UTILITIES
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    #--- Utils
    alejandra
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

    #--- CLI
    deadnix
    statix
    gtrash
    man-pages
    tdf
    tldr
    zenity

    #--- System Tools
    pavucontrol
    psmisc
    lm_sensors
    psutils
    playerctl
    file
    lsof
    ps_mem
    pciutils

    #--- Dev
    jq
    glibc

    #--- Qt Theme Support
    qt6.qt5compat
  ];
}
