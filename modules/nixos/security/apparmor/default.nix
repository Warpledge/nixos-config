#=====================================================================#
# APPARMOR PROFILES
#=====================================================================#
#- Every profile starts in complain mode: nothing is blocked, would-be
#- denials are logged. The machine's apparmor.enforce switches one to
#- enforce; see docs/security/apparmor.md first.
{
  config,
  lib,
  pkgs,
  machine,
  anyUser,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Include Path
  #--------------------------------------------------------------------#
  #- Resolves <tunables/global> and the upstream abstractions; loads no profiles
  security.apparmor.packages = [pkgs.apparmor-profiles];

  #--------------------------------------------------------------------#
  #-- Shared Abstractions
  #--------------------------------------------------------------------#
  security.apparmor.includes = {
    #--- What any graphical app needs to start on this desktop
    "abstractions/nix-desktop-app" = ''
      include <abstractions/base>
      include <abstractions/nameservice>
      include <abstractions/ssl_certs>
      include <abstractions/fonts>
      include <abstractions/mesa>
      include <abstractions/vulkan>
      include <abstractions/wayland>
      include <abstractions/X>
      include <abstractions/audio>
      include <abstractions/gtk>
      include <abstractions/freedesktop.org>

      # The store is world-readable, so reading and running it reveals nothing;
      # children inherit this profile rather than escaping it
      /nix/store/** mrix,
      /etc/** r,
      /sys/** r,
      @{PROC}/sys/** r,
      owner @{PROC}/@{pid}/** r,
      owner @{PROC}/@{pid}/task/[0-9]*/comm rw,
      /dev/dri/** rw,
      owner /dev/shm/** rwk,
      owner /tmp/** rwk,

      # Session sockets, but not the keyring or gpg-agent ones beside them
      owner /run/user/[0-9]*/{wayland-[0-9]*,pipewire-[0-9]*,bus} rw,
      owner /run/user/[0-9]*/{pulse,dconf,at-spi,doc}/** rwk,

      owner @{HOME}/.config/{gtk-3.0,gtk-4.0,fontconfig,dconf,Kvantum,qt5ct,qt6ct}/** r,
      owner @{HOME}/.config/{mimeapps.list,user-dirs.dirs,kdeglobals} r,
      owner @{HOME}/.local/share/{icons,themes,fonts,mime}/** r,
      owner @{HOME}/.icons/** r,
      owner @{HOME}/.cache/{fontconfig,mesa_shader_cache,mesa_shader_cache_db,radv_builtin_shaders}{,/**} rwk,
      owner @{HOME}/.local/share/recently-used.xbel* rwk,
      owner @{HOME}/ r,
      owner @{HOME}/.local/share/ r,
      owner @{HOME}/.local/share/gvfs-metadata/** r,
      owner /tmp/ r,
      owner @{HOME}/.compose-cache{,/**} rwk,

      # Qt settings, saved through a lock file and temporary copies
      owner @{HOME}/.config/QtProject.conf* rwlk,
      owner "@{HOME}/.config/#[0-9]*" rw,

      # dbus-broker here is built without AppArmor, so this is not mediated
      dbus,
      unix,
      signal (send, receive) peer=@{profile_name},
      ptrace (read) peer=@{profile_name},
    '';

    #--- Paths inside a buildFHSEnv/appimageTools bubblewrap sandbox
    "abstractions/nix-fhs-env" = ''
      /usr/** mrix,
      /{bin,sbin,lib,lib32,lib64}/** mrix,
      /.host-etc/** r,
    '';

    #--- mpv's own files, shared by the profiles that end up running it
    "abstractions/nix-mpv" = ''
      /dev/tty rw, # Keyboard controls when run from a terminal
      owner @{HOME}/.config/mpv/** r,
      owner @{HOME}/.local/state/mpv{,/**} rwk,
      owner @{HOME}/.cache/{mpv,yt-dlp}{,/**} rwk,
      owner @{HOME}/.config/yt-dlp/** r,
      owner @{HOME}/.cache/nvl-convert/** r, # NVL CNN shaders
    '';

    #--- Outbound networking
    "abstractions/nix-network" = ''
      network inet,
      network inet6,
      network netlink raw,
    '';
  };

  #--------------------------------------------------------------------#
  #-- Profile Modes
  #--------------------------------------------------------------------#
  #--- Each profile's `state`: enforce once named in the machine's apparmor.enforce
  _module.args.apparmorState = name:
    if lib.elem name machine.apparmor.enforce
    then "enforce"
    else "complain";

  #--- Each loaded profile's mode, for Omni Settings' AppArmor page (the kernel's
  #--- own list is root-only)
  environment.etc."omni-settings/apparmor.json".text =
    builtins.toJSON (lib.mapAttrs (_: p: p.state) config.security.apparmor.policies);

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./archives.nix
      ./evince.nix
      ./yt-dlp.nix
    ]
    #--- Per-app profiles (once any user on the machine has the app)
    ++ lib.optionals anyUser.media.mpv [./mpv.nix]
    ++ lib.optionals anyUser.media.streamlinkTwitchGui [./streamlink.nix]
    ++ lib.optionals anyUser.office.obsidian [./obsidian.nix]
    ++ lib.optionals anyUser.gaming.prismlauncher [./prismlauncher.nix]
    ++ lib.optionals anyUser.media.moku [./tsunagu.nix]
    ++ lib.optionals anyUser.media.tonkatsuBox [./tonkatsu-box.nix]
    ++ lib.optionals anyUser.audio.katanaFloorboard [./katana-floorboard.nix];
}
