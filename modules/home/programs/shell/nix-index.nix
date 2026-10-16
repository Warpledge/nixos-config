#=====================================================================#
# NIX-INDEX AND COMMA
#=====================================================================#
{inputs, ...}: {
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#
  #- The index comes prebuilt from nix-index-database, not a local nix-index run
  programs = {
    #--- Unknown commands print the nixpkgs package that provides them
    nix-index.enable = true;
    #--- `, <cmd>` runs a command from nixpkgs without installing it
    nix-index-database.comma.enable = true;
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [inputs.nix-index-database.homeModules.default];
}
