#=====================================================================#
# SCREEN CAPTURE TOOLS
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#

  home.packages = with pkgs; [
    #--- Screenshots
    #--- screenshot command for controls:
    #--- slurp | grim -g - - | wl-copy
    slurp
    grim
    wl-clipboard
    swappy
    satty

    #--- Screen Recording
    #--- gpu-screen-recorder uses KMS/DRM capture, bypassing PipeWire format negotiation
    #--- (Kooha fails on RDNA4 due to pipewiresrc rejecting new DRM modifiers)
    gpu-screen-recorder
    gpu-screen-recorder-gtk
  ];
}
