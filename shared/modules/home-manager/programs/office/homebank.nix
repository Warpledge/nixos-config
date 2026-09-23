#=====================================================================#
# HOMEBANK CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- HomeBank Package
  #--------------------------------------------------------------------#
  # Lightweight personal accounting: labeled transactions (categories +
  # payees) with an auto-calculated running balance, charts and reports.

  home.packages = with pkgs; [
    homebank
  ];
}
