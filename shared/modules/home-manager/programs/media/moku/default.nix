#=====================================================================#
# MOKU CONFIGURATION
#=====================================================================#
#- Manga, novel and anime reader, built from the pinned `moku` flake
#- input with upstream's nix/moku.nix and two UI fixes, running the
#- Tsunagu backend from the `tsunagu` input. Library, settings and
#- extensions live in ~/.local/share/{tsunagu,io.github.MokuProject.Moku}.
{
  pkgs,
  lib,
  inputs,
  ...
}: let
  src = inputs.moku;
  upstreamVersions = import "${src}/nix/versions.nix";

  #--- Upstream's pnpmHash matches its own nixpkgs pin, not ours; recompute on every bump
  versions =
    upstreamVersions
    // {
      frontend.pnpmHash = "sha256-xHzPYxAC9rW1styY++xOmdVbEqUUB1NDYDq84WJD3WI=";
    };

  tsunagu = import "${inputs.tsunagu}/nix/packages.nix" {inherit pkgs lib;};

  #--- Upstream's vendorHash is stale at v0.4.1. The patch retries a failed cover download
  #--- through the extension's own client (some hand out cover URLs only it can resolve)
  tsunaguServer = tsunagu.tsunagu-server.overrideAttrs (old: {
    vendorHash = "sha256-rPtZJzXAuctkAWPGX/89a7Z9Cr+py510g5QCArOOTJE=";
    patches = (old.patches or []) ++ [./tsunagu-covers.patch];
  });

  #--- Popular/latest go through the suspend getters (extensions-lib 1.6 sources leave the Rx
  #--- fetchers unimplemented), ProtoBuf joins the DI graph as Mihon registers it, and an
  #--- installed extension still loads after its jar-cache copy is cleared
  tsunaguSandbox = tsunagu.tsunagu-sandbox.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./tsunagu-fixes.patch];
  });

  #--- Moku execs TSUNAGU_BIN as is, so the sandbox runtime is set here
  server = pkgs.writeShellScriptBin "tsunagu" ''
    export TSUNAGU_SANDBOX_JAR=${tsunaguSandbox}/share/tsunagu/sandbox.jar
    export JAVA_HOME=${tsunagu.tsunagu-jre}
    export PATH=${lib.makeBinPath [pkgs.ffmpeg-headless]}''${PATH:+:$PATH}
    exec ${tsunaguServer}/bin/tsunagu "$@"
  '';

  #--- Mirrors the runtime lists in upstream's flake.nix, which moku.nix takes as arguments
  gstPlugins = with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];
  runtimeLibs =
    (with pkgs; [
      webkitgtk_4_1
      gtk3
      glib
      glib-networking
      cairo
      pango
      atk
      gdk-pixbuf
      libsoup_3
      openssl
      dbus
      libappindicator-gtk3
      gsettings-desktop-schemas
    ])
    ++ gstPlugins;

  moku =
    (pkgs.callPackage "${src}/nix/moku.nix" {
      inherit src versions runtimeLibs;
      version = versions.moku;
      rustToolchain = pkgs.symlinkJoin {
        name = "rust-toolchain";
        paths = [pkgs.rustc pkgs.cargo];
      };
      gstPluginPath = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins;
      appIcon = "${src}/src/lib/assets/moku-icon.svg";
      tsunaguBin = "${server}/bin/tsunagu";
    })
    .overrideAttrs (old: {
      #--- A per-source filter panel in the source browser, and a filterOptions query the server accepts
      patches = (old.patches or []) ++ [./source-filters.patch];

      #--- 0.13.1's `contain` shrinks WebKitGTK's keyword-search cards below their 2:3 covers, so rows overlap
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace src/lib/components/browse/KeywordTab.svelte \
            --replace-fail ' contain: layout style paint;' ""
        '';
    });
in {
  #--------------------------------------------------------------------#
  #-- Moku
  #--------------------------------------------------------------------#
  home.packages = [moku];
}
