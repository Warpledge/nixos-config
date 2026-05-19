#=====================================================================#
# MIME TYPE ASSOCIATIONS AND DEFAULT APPLICATIONS
#=====================================================================#
{
  lib,
  config,
  ...
}:
with lib; let
  #--------------------------------------------------------------------#
  #-- Default Applications
  #--------------------------------------------------------------------#
  defaultApps = {
    browser = ["zen-beta.desktop"];
    text = ["dev.zed.Zed.desktop"];
    image = ["org.gnome.Loupe.desktop"];
    audio = ["io.github.celluloid_player.Celluloid.desktop"];
    video = ["io.github.celluloid_player.Celluloid.desktop"];
    directory = ["org.gnome.Nautilus.desktop"];
    office = ["libreoffice.desktop"];
    pdf = ["org.gnome.Evince.desktop"];
    terminal = ["kitty.desktop"];
    archive = ["org.gnome.FileRoller.desktop"];
    discord = ["discord.desktop"];
  };

  mimeMap = {
    text = ["text/plain"];
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
    video = [
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/webm"
      "video/x-flv"
      "video/x-matroska"
      "video/x-msvideo"
    ];
    directory = ["inode/directory"];
    browser = [
      "text/html"
      "x-scheme-handler/about"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/unknown"
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
in {
  xdg = {
    configFile."mimeapps.list".force = true;
    mimeApps = {
      enable = true;
      associations.added = associations;
      defaultApplications = associations;
    };
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true; # keep legacy behavior (stateVersion < 26.05)
      extraConfig = {
        SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
      };
    };
  };

  home.sessionVariables = {
    #--- prevent wine from creating file associations
    WINEDLLOVERRIDES = "winemenubuilder.exe=d";
  };
}
