#=====================================================================#
# BOORUSAMA CONFIGURATION
#=====================================================================#
#- Image board browser, the desktop build of the Android client.
#-
#- Not in nixpkgs, so this is the upstream AppImage (v4.5.0, tagged
#- 2026-06-14). Switch to pkgs.boorusama if it ever lands.
#-
#- App data, thumbnail cache and backups (which keep API keys in
#- plaintext) live in a gocryptfs vault that is unlocked only while the
#- app runs. One-time setup per machine: boorusama-vault-init.
{pkgs, ...}: let
  pname = "boorusama";
  version = "4.5.0";
  build = "185";

  src = pkgs.fetchurl {
    url = "https://github.com/khoadng/Boorusama/releases/download/v${version}/${pname}-${version}+${build}-linux-x64.AppImage";
    hash = "sha256-LsKmh0Hw6GyfVpoQPnuDXJ3nlGRj6E3IEQ8FtMPRJMo=";
  };

  #-- Unpacked only to lift out the icon and desktop entry
  contents = pkgs.appimageTools.extract {inherit pname version src;};

  boorusama = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    #--- Linked by the bundled libs but absent from both the AppImage and the
    #--- default FHS env; libmpv is for video playback
    extraPkgs = pkgs: [
      pkgs.libepoxy
      pkgs.lz4
      pkgs.mpv-unwrapped
    ];

    #--- Desktop entry already carries bare Exec and Icon names
    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
      cp -r ${contents}/usr/share/icons $out/share/icons
      chmod -R u+w $out/share/icons
    '';

    meta = {
      description = "A mobile client for booru sites built with Flutter";
      homepage = "https://github.com/khoadng/Boorusama";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  };

  #--------------------------------------------------------------------#
  #-- Data Vault
  #--------------------------------------------------------------------#
  #- The app's data dirs are symlinks into the mountpoint, so they dangle
  #- while it is locked
  vaultPaths = ''
    vault="$HOME/.local/share/boorusama-vault"
    mnt="$HOME/.local/share/boorusama-open"
    export PATH="/run/wrappers/bin:$PATH" # setuid fusermount3
  '';

  #--- Prompts for the vault password, runs the app, locks again on exit
  launcher = pkgs.writeShellApplication {
    name = pname;
    runtimeInputs = [pkgs.gocryptfs pkgs.util-linux pkgs.zenity];
    text = ''
      ${vaultPaths}
      if [ ! -f "$vault/gocryptfs.conf" ]; then
        zenity --error --text="No Boorusama vault yet. Run boorusama-vault-init in a terminal."
        exit 1
      fi

      mounted=0
      if ! mountpoint -q "$mnt"; then
        mkdir -p "$mnt"
        rc=0
        gocryptfs -q -extpass "zenity --password --title=Boorusama" "$vault" "$mnt" || rc=$?
        case $rc in
          0) mounted=1 ;;
          9) exit 1 ;; # dialog cancelled
          12) zenity --error --text="Wrong password."; exit 1 ;;
          10) zenity --error --text="$mnt is not empty, so the vault cannot mount over it."; exit 1 ;;
          *) zenity --error --text="Vault mount failed (gocryptfs exit $rc)."; exit 1 ;;
        esac
      fi

      rc=0
      ${boorusama}/bin/${pname} "$@" || rc=$?
      if [ "$mounted" = 1 ]; then
        fusermount3 -u "$mnt" || fusermount3 -uz "$mnt"
      fi
      exit "$rc"
    '';
  };

  #--- Creates the vault and moves the existing plaintext data into it
  vaultInit = pkgs.writeShellApplication {
    name = "boorusama-vault-init";
    runtimeInputs = [pkgs.gocryptfs pkgs.procps];
    text = ''
      ${vaultPaths}
      if [ -e "$vault/gocryptfs.conf" ]; then
        echo "A vault already exists at $vault" >&2
        exit 1
      fi
      if pgrep -x ${pname} >/dev/null; then
        echo "Close Boorusama first" >&2
        exit 1
      fi

      mkdir -p "$vault" "$mnt"
      gocryptfs -init "$vault"
      echo "Unlock the new vault to move the data in:"
      gocryptfs -q "$vault" "$mnt"
      trap 'fusermount3 -u "$mnt"' EXIT

      migrate() {
        mkdir -p "$2"
        if [ -d "$1" ] && [ ! -L "$1" ]; then
          cp -a "$1/." "$2/"
          rm -rf "$1"
        fi
      }
      #--- Only the paths the app hardcodes get a symlink
      link() {
        migrate "$1" "$2"
        mkdir -p "$(dirname "$1")"
        ln -sfn "$2" "$1"
      }
      link "$HOME/.local/share/com.degenk.boorusama" "$mnt/data"
      link "$HOME/.cache/com.degenk.boorusama" "$mnt/cache"
      migrate "$HOME/Backups/Boorusama" "$mnt/backups"
      echo "Done. Boorusama now asks for this password on launch."
      echo "Set its auto-backup folder to $mnt/backups"
    '';
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  #- The launcher comes first so its bin/boorusama wins over the app's
  home.packages = [
    (pkgs.symlinkJoin {
      name = "${pname}-${version}";
      paths = [launcher boorusama];
    })
    vaultInit
  ];
}
