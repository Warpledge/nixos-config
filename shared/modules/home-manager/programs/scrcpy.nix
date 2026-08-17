#=====================================================================#
# SCRCPY CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- scrcpy Package
  #--------------------------------------------------------------------#
  # Mirror and control an Android device over USB or TCP/IP, with audio
  # forwarding, clipboard sync and drag-and-drop file transfer.
  # Nothing is installed on the device — adb pushes a temporary server at
  # runtime — so it works on de-Googled devices with no vendor app.
  # Wireless use needs `adb tcpip 5555`; that port is already open in
  # nixos/network/core.nix.

  home.packages = with pkgs; [
    scrcpy
  ];
}
