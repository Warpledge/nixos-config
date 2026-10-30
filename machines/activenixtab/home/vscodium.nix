#=====================================================================#
# KYLERJ'S VSCODIUM TWAKS (FLOW Z13)
#=====================================================================#
#- On top of the shared module's settings (modules/home/programs/
#- editors/vscodium.nix).
{...}: {
  #--------------------------------------------------------------------#
  #-- Syntax highlighting
  #--------------------------------------------------------------------#
  #- `inline code` in markdown renders green (both scopes the built-in
  #- markdown grammar uses for it).
  programs.vscodium.profiles.default.userSettings."editor.tokenColorCustomizations" = {
    textMateRules = [
      {
        scope = "markup.inline.raw.markdown, markup.inline.raw.string.markdown";
        settings = {
          foreground = "#98C379";
        };
      }
    ];
  };
}
