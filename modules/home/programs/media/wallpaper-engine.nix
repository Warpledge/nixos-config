#=====================================================================#
# WALLPAPER ENGINE (linux-wallpaperengine)
#=====================================================================#
# Plays Steam Workshop wallpapers; Wallpaper Engine must stay installed in Steam
# for its assets. The DMS linuxWallpaperEngine plugin (Mod+W) runs and picks them,
# and DMS stops drawing its own wallpaper while this toggle is on.
{pkgs, ...}: {
  home.packages = [pkgs.linux-wallpaperengine];
}
