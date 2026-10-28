#=====================================================================#
# MIME TYPE ASSOCIATIONS AND DEFAULT APPLICATIONS
#=====================================================================#
{
  lib,
  config,
  user,
  ...
}:
with lib; let
  #--------------------------------------------------------------------#
  #-- Default Applications
  #--------------------------------------------------------------------#
  #--- The user's defaultApps settings, resolved to apps they have on
  chosen = (import ../../lib/default-apps.nix {inherit lib;}).forUser user;

  defaultApps = {
    browser = [chosen.browser.desktop];
    text = [chosen.textEditor.desktop];
    image = ["org.gnome.Loupe.desktop"];
    audio = ["mpv.desktop"];
    video = ["mpv.desktop"];
    directory = [chosen.fileManager.desktop];
    office = ["libreoffice.desktop"];
    pdf = ["org.gnome.Evince.desktop"];
    terminal = [chosen.terminal.desktop];
    #--- Ark with Dolphin, File Roller otherwise
    archive =
      if chosen.fileManager.name == "dolphin"
      then ["org.kde.ark.desktop"]
      else ["org.gnome.FileRoller.desktop"];
    discord = ["discord.desktop"];
    freetube = ["freetube.desktop"];
    #--- youtube-dispatch exists only with FreeTube on
    webLinks =
      if user.media.freetube
      then ["youtube-dispatch.desktop"]
      else [chosen.browser.desktop];
  };

  mimeMap = {
    #--- code and markup types listed so micro, Helix and the DMS notepad don't take them
    text = [
      "text/plain"
      "application/sql"
      "application/x-perl"
      "application/x-php"
      "application/x-shellscript"
      "application/xml"
      "text/css"
      "text/markdown"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-makefile"
      "text/x-patch"
      "text/x-python"
      "text/x-python3"
      "text/x-shellscript"
      "text/x-tex"
    ];
    image = [
      "image/bmp"
      "image/gif"
      "image/jpeg"
      "image/jpg"
      "image/png"
      "image/svg+xml"
      "image/tiff"
      "image/vnd.microsoft.icon"
      "image/webp"
    ];
    audio = [
      "audio/aac"
      "audio/mpeg"
      "audio/ogg"
      "audio/opus"
      "audio/wav"
      "audio/webm"
      "audio/x-matroska"
    ];
    #--- Constrict and Video Trimmer claim video types too; any left out opens in them
    video = [
      "video/3gpp"
      "video/3gpp2"
      "video/dv"
      "video/matroska"
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/quicktime"
      "video/vnd.rn-realvideo"
      "video/webm"
      "video/x-flic"
      "video/x-flv"
      "video/x-matroska"
      "video/x-mjpeg"
      "video/x-ms-wmv"
      "video/x-msvideo"
      "video/x-ogm+ogg"
    ];
    directory = ["inode/directory"];
    browser = [
      "text/html"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
    #--- routed through youtube-dispatch so YouTube links reach FreeTube
    webLinks = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    office = [
      "application/vnd.oasis.opendocument.text"
      "application/vnd.oasis.opendocument.spreadsheet"
      "application/vnd.oasis.opendocument.presentation"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "application/msword"
      "application/vnd.ms-excel"
      "application/vnd.ms-powerpoint"
      "application/rtf"
    ];
    pdf = ["application/pdf"];
    terminal = ["terminal"];
    archive = [
      "application/zip"
      "application/rar"
      "application/7z"
      "application/x-tar"
      "application/gzip"
      "application/x-gzip"
      "application/x-xz"
      "application/x-bzip2"
    ];
    discord = ["x-scheme-handler/discord"];
    freetube = ["x-scheme-handler/freetube"];
  };

  associations = with lists;
    listToAttrs (
      flatten (
        mapAttrsToList (
          key: map (type: attrsets.nameValuePair type defaultApps."${key}")
        )
        mimeMap
      )
    );
  #--- Types picked on Omni Settings' File Types page win over these
  resolved = associations // mapAttrs (_: app: [app]) user.mimeTypes;
in {
  xdg = {
    configFile."mimeapps.list".force = true;
    mimeApps = {
      enable = true;
      associations.added = resolved;
      defaultApplications = resolved;
    };
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true; # keep legacy behavior (stateVersion < 26.05)
      extraConfig = {
        SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
      };
    };

    #--- GIO can't launch Terminal=true apps (micro, Helix) in a terminal without this
    terminal-exec = {
      enable = true;
      settings.default = [chosen.terminal.desktop];
    };
  };

  home.sessionVariables = {
    #--- prevent wine from creating file associations
    WINEDLLOVERRIDES = "winemenubuilder.exe=d";
  };
}
