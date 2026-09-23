#=====================================================================#
# SYSTEM PACKAGES
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- System Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    lshw # Hardware inspection
    fd # File finder (faster than find)
    bc # Calculator
    gcc # C/C++ compiler
    git # Version control
    git-ignore # .gitignore templates
    xdg-utils # XDG desktop utilities
    wget # HTTP download utility
  ];
}
