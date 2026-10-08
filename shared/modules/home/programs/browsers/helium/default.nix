#=====================================================================#
# HELIUM BROWSER CONFIGURATION
#=====================================================================#
{
  inputs,
  pkgs,
  ...
}: let
  #--------------------------------------------------------------------#
  #-- Helium Flags
  #--------------------------------------------------------------------#
  # Helium ignores ~/.config/helium-flags.conf, so flags go on the wrapper.
  # --spoof-webgl-info is only the helium://flags entry name; the switch is the SpoofWebGLInfo feature
  helium = pkgs.symlinkJoin {
    name = "helium";
    paths = [inputs.helium.packages.x86_64-linux.helium];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      #--- Anti-fingerprinting
      # Repeats the upstream wrapper's WaylandWindowDecorations: a later --enable-features replaces an earlier one
      # WebGL renderer/vendor match the values Zen reports. Helium decodes %2C but not %20, so spaces stay literal
      wrapProgram $out/bin/helium --add-flag \
        "--enable-features=WaylandWindowDecorations,SpoofWebGLInfo:renderer/Radeon R9 200 Series%2C or similar/vendor/AMD"
    '';
  };
in {
  #--------------------------------------------------------------------#
  #-- Helium Browser Package
  #--------------------------------------------------------------------#
  home.packages = [helium];
}
