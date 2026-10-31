#=====================================================================#
# SCRCPY CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- scrcpy Package
  #--------------------------------------------------------------------#
  # Nothing is installed on the device — adb pushes a temporary server at
  # runtime — so it works on de-Googled devices with no vendor app.
  # Wireless use needs `adb tcpip 5555`; that port is open in
  # nixos/network/firewall.nix.

  home.packages = with pkgs; [
    scrcpy
  ];

  #--- Launcher entry
  # The packaged entry's `\\$SHELL -i -c scrcpy` reaches DMS with the backslash
  # intact, so the launcher runs a command named "$SHELL" and nothing opens.
  xdg.desktopEntries.scrcpy = {
    name = "scrcpy";
    genericName = "Android Remote Control";
    comment = "Display and control your Android device";
    exec = "scrcpy";
    icon = "scrcpy";
    terminal = false;
    categories = ["Utility" "RemoteAccess"];
  };
}
