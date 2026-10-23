#=====================================================================#
# PROGRAMS MODULE IMPORTS
#=====================================================================#
#- `user` is this person's settings.nix, passed in by `import ./programs user`
#- (home/default.nix) so the imports below can read it
user: {lib, ...}: {
  _file = ./default.nix; # Error messages name this file, not the importer

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      #--- Editors (non-configurable)
      ./editors/micro.nix

      #--- Fetch
      ./fetch/fastfetch.nix

      #--- Media (non-configurable)
      ./media/screen-capture.nix

      #--- Settings app (every user)
      ./system/nixos-settings

      #--- Shell
      ./shell/p10k/p10k.nix
      ./shell/atuin.nix
      ./shell/direnv.nix
      ./shell/eza.nix
      ./shell/fzf.nix
      ./shell/nix-index.nix
      ./shell/skim.nix
      ./shell/starship.nix
      ./shell/tmux.nix
      ./shell/zoxide.nix
      ./shell/zsh.nix

      #--- Other
      ./android/android.nix
      (import ./gaming user)
      ./git/git.nix
      ./options.nix
      ./utilities.nix
    ]
    #--- Packages added from NixOS Settings' Packages tab
    ++ lib.optionals (user.userPackages != {}) [./user-packages.nix]
    #--- File Browsers (controlled by user settings)
    ++ lib.optionals user.fileBrowsers.nautilus [./file-browsers/nautilus.nix]
    ++ lib.optionals user.fileBrowsers.dolphin [./file-browsers/dolphin]
    ++ lib.optionals user.fileBrowsers.yazi [./file-browsers/yazi.nix]
    ++ lib.optionals user.fileBrowsers.duxFiles [./file-browsers/dux-files.nix]
    #--- Browsers (controlled by user settings)
    ++ lib.optionals user.browsers.zen [./browsers/zen]
    ++ lib.optionals user.browsers.mullvad [./browsers/mullvad.nix]
    ++ lib.optionals user.browsers.helium [./browsers/helium.nix]
    ++ lib.optionals user.browsers.ferdium [./browsers/ferdium.nix]
    #--- Editors (controlled by user settings)
    ++ lib.optionals user.editors.helix [./editors/helix.nix]
    ++ lib.optionals user.editors.zed [./editors/zed.nix]
    ++ lib.optionals user.editors.vscodium [./editors/vscodium.nix]
    #--- Media (controlled by user settings)
    ++ lib.optionals user.media.mpv [./media/mpv.nix]
    ++ lib.optionals user.media.spotify [./media/spotify.nix]
    ++ lib.optionals user.media.freetube [./media/freetube]
    ++ lib.optionals user.media.videoTrimmer [./media/video-trimmer.nix]
    ++ lib.optionals user.media.constrict [./media/constrict.nix]
    ++ lib.optionals user.media.streamlinkTwitchGui [./media/streamlink-twitch-gui.nix]
    ++ lib.optionals user.media.moku [./media/moku]
    ++ lib.optionals user.media.boorusama [./media/boorusama.nix]
    ++ lib.optionals (user.wallpaper == "engine") [./media/wallpaper-engine.nix]
    ++ lib.optionals user.media.tonkatsuBox [./media/tonkatsu-box.nix]
    #--- Terminals (controlled by user settings)
    ++ lib.optionals user.terminals.kitty [./terminals/kitty.nix]
    ++ lib.optionals user.terminals.ghostty [./terminals/ghostty.nix]
    #--- Graphics (controlled by user settings)
    ++ lib.optionals user.graphics.blender [./graphics/blender.nix]
    ++ lib.optionals user.graphics.krita [./graphics/krita.nix]
    ++ lib.optionals user.graphics.affinity [./graphics/affinity.nix]
    #--- ArtCraft (controlled by user settings)
    ++ lib.optionals user.artcraft.photocraft [./artcraft/photocraft.nix]
    ++ lib.optionals user.artcraft.lightcraft [./artcraft/lightcraft.nix]
    ++ lib.optionals user.artcraft.vectorcraft [./artcraft/vectorcraft.nix]
    ++ lib.optionals user.artcraft.designcraft [./artcraft/designcraft.nix]
    ++ lib.optionals user.artcraft.figcraft [./artcraft/figcraft.nix]
    ++ lib.optionals user.artcraft.effectcraft [./artcraft/effectcraft.nix]
    ++ lib.optionals user.artcraft.filmcraft [./artcraft/filmcraft.nix]
    ++ lib.optionals user.artcraft.soundcraft [./artcraft/soundcraft.nix]
    ++ lib.optionals user.artcraft.cadcraft [./artcraft/cadcraft.nix]
    ++ lib.optionals user.artcraft.pdfcraft [./artcraft/pdfcraft.nix]
    ++ lib.optionals user.artcraft.wordcraft [./artcraft/wordcraft.nix]
    ++ lib.optionals user.artcraft.gridcraft [./artcraft/gridcraft.nix]
    ++ lib.optionals user.artcraft.deckcraft [./artcraft/deckcraft.nix]
    #--- Audio (controlled by user settings)
    ++ lib.optionals user.audio.reaper [./audio/reaper.nix]
    ++ lib.optionals (with user.audio; guitarix || tone3000 || katanaFloorboard) [(import ./audio/guitar user)]
    #--- Office (controlled by user settings)
    ++ lib.optionals user.office.thunderbird [./office/thunderbird.nix]
    ++ lib.optionals user.office.obsidian [./office/obsidian.nix]
    ++ lib.optionals user.office.homebank [./office/homebank.nix]
    #--- Security (controlled by user settings)
    ++ lib.optionals user.security.bleachbit [./security/bleachbit.nix]
    ++ lib.optionals user.security.keepassxc [./security/keepassxc.nix]
    #--- System Tools (controlled by user settings)
    ++ lib.optionals user.system.resources [./system/resources.nix]
    #--- Android Screen Mirroring (controlled by user settings)
    ++ lib.optionals user.scrcpy.enable [./android/scrcpy.nix]
    #--- AI Tools (controlled by user settings)
    ++ lib.optionals user.claude.enable [./ai/claude.nix]
    ++ lib.optionals user.claudeDesktop.enable [./ai/claude-desktop.nix]
    ++ lib.optionals user.opencode.enable [./ai/opencode.nix]
    ++ lib.optionals user.lmstudio.enable [./ai/lmstudio.nix]
    ++ lib.optionals user.llamaSwap.enable [./ai/llama-swap.nix]
    ++ lib.optionals (user.claude.enable || user.opencode.enable) [./ai/mcp.nix]
    ++ lib.optionals (user.opencode.enable || (user.editors.zed && (user.llamaSwap.enable || user.claude.enable))) [./ai/agent-skills.nix]
    #--- Discord (controlled by user settings)
    ++ lib.optionals (user.discord.goofcord || user.discord.vesktop) [./discord/discord.nix]
    ++ lib.optionals user.discord.arrpc.enable [./discord/arrpc.nix];
}
