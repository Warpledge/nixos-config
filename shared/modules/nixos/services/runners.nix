#=====================================================================#
# APPLICATION EXECUTION ENVIRONMENT (FHS, APPIMAGE, NIX-LD)
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- System Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = [
    pkgs.appimage-run # AppImage runner utility
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
        pkgs.buildFHSEnv (base
          // {
            name = "fhs"; # FHS environment for non-NixOS binaries
            targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config];
            profile = "export FHS=1";
            runScript = "bash";
            extraOutputsToInstall = ["dev"];
          })
    )
  ];

  #--------------------------------------------------------------------#
  #-- AppImage Support
  #--------------------------------------------------------------------#
  boot.binfmt.registrations = lib.genAttrs ["appimage" "AppImage"] (_: {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
    magicOrExtension = "\\x7fELF....AI\\x02";
  });

  #--------------------------------------------------------------------#
  #-- Nix-LD Configuration
  #--------------------------------------------------------------------#
  programs.nix-ld = {
    enable = true; # Enable nix-ld for unpatched Linux binaries
    libraries = with pkgs; [
      stdenv.cc.cc # C compiler runtime
      openssl # TLS/SSL library
      curl # HTTP client library
      glib # Core library
      util-linux # Linux utilities
      glibc # C standard library
      icu # Unicode support
      libunwind # Stack unwinding
      libuuid # UUID generation
      zlib # Compression library
      libsecret # Secure credential storage
      freetype # Font rendering
      libglvnd # OpenGL vendor library
      libnotify # Desktop notifications
      SDL2 # Graphics library
      vulkan-loader # Vulkan API loader
      gdk-pixbuf # Image loading library
      fuse # Filesystem in userspace
    ];
  };
}
