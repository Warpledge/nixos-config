#=====================================================================#
# DOLPHIN FILE BROWSER CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  # Colours and icons come from theme/qt.nix (qt5ct/qt6ct, kdeglobals)

  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.ark # archives; adds Compress/Extract to Dolphin's context menu
  ];

  #--------------------------------------------------------------------#
  #-- Application Menu
  #--------------------------------------------------------------------#
  # KService lists apps from this menu; outside Plasma there is none, which
  # leaves Dolphin's Open With menu empty
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';
}
