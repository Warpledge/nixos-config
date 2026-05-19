#=====================================================================#
# ZEN BROWSER UI CONFIGURATION
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- UI Layout & Customization
  #--------------------------------------------------------------------#

  #--- Vertical tabs on the right side
  "zen.tabs.vertical.right-side" = true;

  #--- Toolbar customization (customize toolbar button placement)
  "zen.view.use-single-toolbar" = false;
  "browser.uiCustomization.state" = builtins.toJSON {
    placements = {
      widget-overflow-fixed-list = [];
      unified-extensions-area = [
        "_20fc2e06-e3e4-4b2b-812b-ab431220cada_-browser-action"
        "sponsorblocker_ajay_app-browser-action"
        "_b86e4813-687a-43e6-ab65-0bde4ab75758_-browser-action"
        "firefoxcolor_mozilla_com-browser-action"
        "tubemod_extension_com-browser-action"
        "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
        "jid1-bofifl9vbdl2zq_jetpack-browser-action"
      ];
      nav-bar = [
        "back-button"
        "forward-button"
        "stop-reload-button"
        "vertical-spacer"
        "urlbar-container"
        "customizableui-special-spring1"
        "personal-bookmarks"
        "customizableui-special-spring2"
        "unified-extensions-button"
        "ublock0_raymondhill_net-browser-action"
        "addon_darkreader_org-browser-action"
        "_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action"
        "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
      ];
      toolbar-menubar = ["menubar-items"];
      TabsToolbar = ["tabbrowser-tabs"];
      vertical-tabs = [];
      PersonalToolbar = ["import-button"];
      zen-sidebar-top-buttons = ["zen-toggle-compact-mode"];
      zen-sidebar-foot-buttons = [
        "downloads-button"
        "zen-workspaces-button"
        "zen-create-new-button"
      ];
    };
    seen = [
      "developer-button"
      "screenshot-button"
      "addon_darkreader_org-browser-action"
      "_b86e4813-687a-43e6-ab65-0bde4ab75758_-browser-action"
      "ublock0_raymondhill_net-browser-action"
      "firefoxcolor_mozilla_com-browser-action"
      "tubemod_extension_com-browser-action"
      "sponsorblocker_ajay_app-browser-action"
      "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
      "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
      "_20fc2e06-e3e4-4b2b-812b-ab431220cada_-browser-action"
      "_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action"
      "jid1-bofifl9vbdl2zq_jetpack-browser-action"
    ];
    dirtyAreaCache = [
      "nav-bar"
      "vertical-tabs"
      "zen-sidebar-foot-buttons"
      "PersonalToolbar"
      "toolbar-menubar"
      "TabsToolbar"
      "zen-sidebar-top-buttons"
      "unified-extensions-area"
    ];
    currentVersion = 23;
    newElementCount = 6;
  };

  #--------------------------------------------------------------------#
  #-- UI & User Experience (Peskyfox)
  #--------------------------------------------------------------------#

  #--- Mozilla UI Tweaks
  "browser.uitour.enabled" = false;
  "browser.privatebrowsing.vpnpromourl" = "";
  "extensions.getAddons.showPane" = false;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "browser.discovery.enabled" = false;
  "browser.shell.checkDefaultBrowser" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
  "browser.preferences.moreFromMozilla" = false;
  "browser.tabs.tabmanager.enabled" = false;
  "browser.aboutConfig.showWarning" = false;
  "browser.aboutwelcome.enabled" = false;
  "browser.tabs.firefox-view" = false;

  #--- Theme Adjustments
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "browser.compactmode.show" = true;
  "browser.display.focus_ring_on_anything" = true;
  "browser.display.focus_ring_style" = 0;
  "browser.display.focus_ring_width" = 0;
  "layout.css.prefers-color-scheme.content-override" = 2;
  "browser.privateWindowSeparation.enabled" = false;

  #--- Cookie Banner Handling
  "cookiebanners.service.mode" = 1;
  "cookiebanners.service.mode.privateBrowsing" = 1;
  "cookiebanners.service.enableGlobalRules" = true;

  #--- Fullscreen Notice
  "full-screen-api.transition-duration.enter" = "0 0";
  "full-screen-api.transition-duration.leave" = "0 0";
  "full-screen-api.warning.delay" = -1;
  "full-screen-api.warning.timeout" = 0;

  #--- URL Bar Features
  "browser.urlbar.suggest.calculator" = true;
  "browser.urlbar.unitConversion.enabled" = true;
  "browser.urlbar.trending.featureGate" = false;

  #--- New Tab Page
  "browser.newtabpage.activity-stream.feeds.topsites" = false;
  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

  #--- Pocket Integration
  "extensions.pocket.enabled" = false;

  #--- Download Behavior
  "browser.download.useDownloadDir" = false;
  "browser.download.always_ask_before_handling_new_types" = true;
  "browser.download.manager.addToRecentDocs" = false;

  #--- PDF Viewer
  "browser.download.open_pdf_attachments_inline" = true;

  #--- General Tab Behavior
  "browser.bookmarks.openInTabClosesMenu" = false;
  "browser.menu.showViewImageInfo" = true;
  "findbar.highlightAll" = true;
  "layout.word_select.eat_space_to_next_word" = false;
  "ui.key.menuAccessKeyFocuses" = false;
}
