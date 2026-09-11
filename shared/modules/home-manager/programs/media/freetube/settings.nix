{...}: {
  #=====================================================================#
  # FREETUBE SETTINGS
  #=====================================================================#
  # Stylix has no FreeTube target, so theming rides on the app's own
  # bundled Catppuccin palette. Home Manager copies these keys over
  # settings.db whenever they change, wiping anything tuned in the GUI.

  programs.freetube.settings = {
    #--------------------------------------------------------------------#
    #-- Theme
    #--------------------------------------------------------------------#
    baseTheme = "catppuccinMocha";
    mainColor = "CatppuccinMochaMauve";
    secColor = "CatppuccinMochaLavender";
    barColor = false; # tints the top bar with mainColor

    #--------------------------------------------------------------------#
    #-- Backend
    #--------------------------------------------------------------------#
    backendPreference = "local"; # built-in extractor, no Invidious instance
    backendFallback = false; # try the other backend when the preferred one fails
    checkForUpdates = false; # updates come from nixpkgs
    region = "US"; # trending region
    currentLocale = "en-US";
    openDeepLinksInNewWindow = true;
    settingsSectionSortEnabled = false;

    #--------------------------------------------------------------------#
    #-- Interface
    #--------------------------------------------------------------------#
    uiScale = 120; # comment text 14px -> 16.8px
    expandSideBar = false;
    hideLabelsSideBar = true;
    hideHeaderLogo = false;
    hideSearchBar = false;
    showDistractionFreeTitles = true; # strips ALL CAPS from titles
    displayVideoPlayButton = false;
    enableScreenshot = false;

    #--------------------------------------------------------------------#
    #-- Playback
    #--------------------------------------------------------------------#
    autoplayVideos = false;
    playNextVideo = false;
    defaultViewingMode = "theatre";
    defaultQuality = "1440";
    videoPlaybackRateMouseScroll = true;

    #--------------------------------------------------------------------#
    #-- Feed
    #--------------------------------------------------------------------#
    hideTrendingVideos = false;
    hideUpcomingPremieres = true;
    hideSubscriptionsShorts = true;
    hideSubscriptionsLive = false;
    hideSubscriptionsCommunity = true;
    hideActiveSubscriptions = false;
    hidePlaylists = false;
    hideChannelHome = true;
    hideChannelShorts = true;
    hideLiveChat = false;
    showFamilyFriendlyOnly = false;
    disableChannelLinks = false;
    unsubscriptionPopupStatus = true; # confirm before unsubscribing

    #--------------------------------------------------------------------#
    #-- Enhancements
    #--------------------------------------------------------------------#
    useSponsorBlock = true;
    useDeArrowTitles = true;
    useDeArrowThumbnails = false; # sparse coverage, frame grabs often worse
  };
}
