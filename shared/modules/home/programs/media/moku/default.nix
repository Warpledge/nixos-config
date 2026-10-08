#=====================================================================#
# MOKU CONFIGURATION
#=====================================================================#
#- Manga, novel and anime reader, built from the pinned `moku` flake
#- input with upstream's nix/moku.nix and two UI fixes, running the
#- Tsunagu backend from the `tsunagu` input with a bridge that turns each
#- parser in a Kototoro plugin repo into its own extension (sources in
#- ./tsunagu). Library, settings and extensions live in
#- ~/.local/share/{tsunagu,io.github.MokuProject.Moku}.
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
      frontend.pnpmHash = "sha256-77nWx3b8XkaCPzfdXemJBOpUFKSTiRTi/bsgnoB3k4M=";
    };

  tsunagu = import "${inputs.tsunagu}/nix/packages.nix" {inherit pkgs lib;};

  #--- The only Kototoro plugin the sandbox runs (TSUNAGU_KOTOTORO_JAR),
  #--- whatever jar a repo index lists; kototoroApi is its dex turned back
  #--- into JVM classes for compiling the bridge
  kototoroPlugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/skepsun/kototoro-parsers/58950ebc43b53cbfd8d4523544e870fd96b0c1cc/apk/plugin.jar"; # v1.0.134
    hash = "sha256-F0s6i606OsqGaoEA9CTdTTCZHbqml6DLsuCu0KQaWro=";
  };
  kototoroApi = pkgs.runCommand "kototoro-api.jar" {} ''
    ${pkgs.dex2jar}/bin/d2j-dex2jar -o $out ${kototoroPlugin}
  '';

  #--- Loaded only for Kototoro parsers, at the versions the plugin is built against
  jsoup = pkgs.fetchurl {
    url = "https://repo1.maven.org/maven2/org/jsoup/jsoup/1.21.2/jsoup-1.21.2.jar";
    hash = "sha256-8FSW4lVzR1nw1LVjLaeyT4ExMUfHjGnpCtBF0JYZE0Q=";
  };
  collection = pkgs.fetchurl {
    url = "https://dl.google.com/android/maven2/androidx/collection/collection-jvm/1.5.0/collection-jvm-1.5.0.jar";
    hash = "sha256-cLNZJOS6vN/6N9Dlde4DnFai2XEjNCYkxItgMjNwQ0E=";
  };

  #--- Upstream's vendorHash is stale at v0.4.1. server.patch expands a
  #--- Kototoro repo on sync (from the pinned plugin, never the index's jar)
  #--- and retries a failed cover download through the extension's own
  #--- client
  tsunaguServer = tsunagu.tsunagu-server.overrideAttrs (old: {
    vendorHash = "sha256-rPtZJzXAuctkAWPGX/89a7Z9Cr+py510g5QCArOOTJE=";
    patches = (old.patches or []) ++ [./tsunagu/server.patch];
    postPatch =
      (old.postPatch or "")
      + ''
        cp ${./tsunagu/backend/internal/sync/kototoro.go} backend/internal/sync/kototoro.go
      '';
  });

  #--- sandbox.patch loads the Kototoro bridge. tsunagu-fixes.patch:
  #--- popular/latest go through the suspend getters (extensions-lib 1.6
  #--- sources leave the Rx fetchers unimplemented), ProtoBuf joins the DI
  #--- graph as Mihon registers it, and an installed extension still loads
  #--- after its jar-cache copy is cleared
  tsunaguSandbox = tsunagu.tsunagu-sandbox.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./tsunagu/sandbox.patch ./tsunagu-fixes.patch];
    #--- Nested jars are named *.lib, since Shadow would unpack a *.jar into
    #--- the sandbox classpath
    postPatch =
      old.postPatch
      + ''
        cp -r ${./tsunagu/sandbox/src}/. src/
        chmod -R u+w src
        mkdir -p kototoro/resources/kototoro/libs
        cp ${kototoroApi} kototoro/kototoro-api.jar
        cp ${jsoup} kototoro/resources/kototoro/libs/jsoup.lib
        cp ${collection} kototoro/resources/kototoro/libs/collection.lib
        printf 'jsoup.lib\ncollection.lib\n' > kototoro/resources/kototoro/libs/index.txt
      '';
  });

  #--- Moku execs TSUNAGU_BIN as is, so the sandbox runtime is set here
  server = pkgs.writeShellScriptBin "tsunagu" ''
    export TSUNAGU_SANDBOX_JAR=${tsunaguSandbox}/share/tsunagu/sandbox.jar
    export TSUNAGU_KOTOTORO_JAR=${kototoroPlugin}
    export JAVA_HOME=${tsunagu.tsunagu-jre}
    export PATH=${lib.makeBinPath [pkgs.ffmpeg-headless]}''${PATH:+:$PATH}

    #--- Mullvad's in-tunnel resolver SERVFAILs some image CDNs; Quad9's DoH
    #--- answers them
    export SANDBOX_DOH=https://dns.quad9.net/dns-query

    exec ${tsunaguServer}/bin/tsunagu "$@"
  '';

  #--- Mirrors the runtime lists in upstream's flake.nix, which moku.nix
  #--- takes as arguments
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
      #--- A per-source filter panel in the source browser, and a
      #--- filterOptions query the server accepts
      patches = (old.patches or []) ++ [./source-filters.patch];

      #--- 0.13.1's `contain` shrinks WebKitGTK's keyword-search cards below
      #--- their 2:3 covers, so rows overlap
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
