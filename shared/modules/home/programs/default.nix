#=====================================================================#
# PROGRAMS MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
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

      #--- Shell
      ./shell/p10k/p10k.nix
      ./shell/atuin.nix
      ./shell/eza.nix
      ./shell/fzf.nix
      ./shell/skim.nix
      ./shell/starship.nix
      ./shell/tmux.nix
      ./shell/zoxide.nix
      ./shell/zsh.nix

      #--- Other
      ./android/android.nix
      ./discord/discord.nix
      ./gaming
      ./git/git.nix
      ./options.nix
      ./utilities/utilities.nix
    ]
    #--- File Browsers (controlled by hostConfig)
    ++ lib.optionals hostConfig.fileBrowsers.nautilus [./file-browsers/nautilus.nix]
    ++ lib.optionals hostConfig.fileBrowsers.yazi [./file-browsers/yazi.nix]
    #--- Browsers (controlled by hostConfig)
    ++ lib.optionals hostConfig.browsers.zen [./browsers/zen]
    ++ lib.optionals hostConfig.browsers.mullvad [./browsers/mullvad]
    ++ lib.optionals hostConfig.browsers.helium [./browsers/helium]
    ++ lib.optionals hostConfig.browsers.ferdium [./browsers/ferdium.nix]
    #--- Editors (controlled by hostConfig)
    ++ lib.optionals hostConfig.editors.helix [./editors/helix.nix]
    ++ lib.optionals hostConfig.editors.zed [./editors/zed.nix]
    #--- Media (controlled by hostConfig)
    ++ lib.optionals hostConfig.media.mpv [./media/mpv.nix]
    ++ lib.optionals hostConfig.media.spotify [./media/spotify.nix]
    ++ lib.optionals hostConfig.media.freetube [./media/freetube]
    ++ lib.optionals hostConfig.media.videoTrimmer [./media/video-trimmer.nix]
    ++ lib.optionals hostConfig.media.streamlinkTwitchGui [./media/streamlink-twitch-gui.nix]
    ++ lib.optionals hostConfig.media.moku [./media/moku]
    ++ lib.optionals hostConfig.media.seanime [./media/seanime.nix]
    ++ lib.optionals hostConfig.media.boorusama [./media/boorusama.nix]
    ++ lib.optionals hostConfig.media.tonkatsuBox [./media/tonkatsu-box.nix]
    #--- Terminals (controlled by hostConfig)
    ++ lib.optionals hostConfig.terminals.kitty [./terminals/kitty.nix]
    ++ lib.optionals hostConfig.terminals.ghostty [./terminals/ghostty.nix]
    #--- Graphics (controlled by hostConfig)
    ++ lib.optionals hostConfig.graphics.blender [./graphics/blender.nix]
    ++ lib.optionals hostConfig.graphics.krita [./graphics/krita.nix]
    ++ lib.optionals hostConfig.graphics.affinity [./graphics/affinity.nix]
    #--- Audio (controlled by hostConfig)
    ++ lib.optionals hostConfig.audio.reaper [./audio/reaper.nix]
    ++ lib.optionals (with hostConfig.audio; guitarix || tone3000 || katanaFloorboard) [./audio/guitar]
    #--- Office (controlled by hostConfig)
    ++ lib.optionals hostConfig.office.thunderbird [./office/thunderbird.nix]
    ++ lib.optionals hostConfig.office.obsidian [./office/obsidian.nix]
    ++ lib.optionals hostConfig.office.homebank [./office/homebank.nix]
    #--- Security (controlled by hostConfig)
    ++ lib.optionals hostConfig.security.bleachbit [./security/bleachbit.nix]
    ++ lib.optionals hostConfig.security.keepassxc [./security/keepassxc.nix]
    #--- Android Screen Mirroring (controlled by hostConfig)
    ++ lib.optionals hostConfig.scrcpy.enable [./android/scrcpy.nix]
    #--- AI Tools (controlled by hostConfig)
    ++ lib.optionals hostConfig.claude.enable [./ai/claude.nix]
    ++ lib.optionals hostConfig.opencode.enable [./ai/opencode.nix]
    ++ lib.optionals hostConfig.lmstudio.enable [./ai/lmstudio.nix]
    ++ lib.optionals (hostConfig.claude.enable || hostConfig.opencode.enable) [./ai/mcp.nix]
    #--- Discord Rich Presence / Game Detection (controlled by hostConfig)
    ++ lib.optionals hostConfig.discord.arrpc.enable [./discord/arrpc.nix];
}
