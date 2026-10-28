#=====================================================================#
# GHOSTTY (TOUCHSCREEN)
#=====================================================================#
#- Ghostty patched so a tap on the touchscreen clicks where the finger
#- is; it builds from source, as the patched package isn't cached.
{pkgs, ...}: {
  programs.ghostty = {
    package = pkgs.ghostty.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./ghostty-touch.patch];
    });

    #--- DMS's matugen writes this theme; the shared module doesn't load it yet
    settings.theme = "dankcolors";

    settings.custom-shader = "${./ghostty-cursor.glsl}";
  };
}
