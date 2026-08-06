#=====================================================================#
# COSMIC DEFAULT APPLICATION FIX
#=====================================================================#
{config, ...}: {
  #--------------------------------------------------------------------#
  #-- Desktop-Prefixed mimeapps.list
  #--------------------------------------------------------------------#
  # COSMIC resolves default apps through the cosmic-mime-apps crate, which
  # follows the mime-apps spec: `~/.config/<desktop>-mimeapps.list` is read
  # *before* `~/.config/mimeapps.list`. cosmic-session ships
  # DesktopNames=COSMIC, and the crate lowercases it, so the winning file is
  # `~/.config/cosmic-mimeapps.list`.
  #
  # On the first COSMIC login `load_user_mimeapps()` copies the plain
  # mimeapps.list into that desktop-prefixed name and writes only there from
  # then on. Nothing ever refreshes the copy, so every default declared in
  # shared/modules/home-manager/mime.nix is frozen at whatever it looked like
  # during that first session and later rebuilds appear to do nothing.
  #
  # Pointing both names at the same generated file keeps the two in sync.
  # This mirrors what home-manager already does for the deprecated
  # ~/.local/share/applications/mimeapps.list location.
  #
  # Trade-off: the file becomes a read-only store symlink, so Settings ->
  # Default Applications (and "Set as default" in cosmic-files) can no longer
  # write to it. Reading is unaffected, so the declared defaults still apply
  # everywhere. Change defaults in mime.nix, not in the GUI.
  xdg.configFile."cosmic-mimeapps.list" = {
    force = true;
    source = config.xdg.configFile."mimeapps.list".source;
  };
}
