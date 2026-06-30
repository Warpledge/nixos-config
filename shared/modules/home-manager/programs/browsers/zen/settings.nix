#=====================================================================#
# ZEN BROWSER SETTINGS
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Session Restore
  #--------------------------------------------------------------------#

  "browser.startup.page" = 3;
  "browser.sessionstore.resumeSessionOnce" = true;
  "browser.sessionstore.max_tabs_undo" = 20;
  "browser.tabs.warnOnClose" = false;

  #--------------------------------------------------------------------#
  #-- Performance
  #--------------------------------------------------------------------#

  #--- Graphics
  "gfx.canvas.accelerated.cache-items" = 4096;
  "gfx.canvas.accelerated.cache-size" = 512;
  "gfx.content.skia-font-cache-size" = 20;

  #--- Caching (Disk, Media, Image)
  "browser.cache.jsbc_compression_level" = 3;
  "media.memory_cache_max_size" = 65536;
  "media.cache_readahead_limit" = 7200;
  "media.cache_resume_treshold" = 3600;
  "image.mem.decode_bytes_at_a_time" = 32768;

  #--- Network Performance
  "network.buffer.cache.size" = 262144;
  "network.buffer.cache.count" = 128;
  "network.http.max-connections" = 1800;
  "network.http.max-persistent-connections-per-server" = 10;
  "network.http.max-urgent-start-excessive-connections-per-host" = 5;
  "network.http.pacing.requests.enabled" = false;
  "network.dnsCacheExpiration" = 3600;
  "network.dns.max_high_priority_threads" = 8;
  "network.ssl_tokens_cache_capacity" = 10240;

  #--- Speculative Loading
  "network.dns.disablePrefetch" = true;
  "network.dns.disablePrefetchFromHTTPS" = true;
  "network.prefetch-next" = false;
  "network.predictor.enabled" = false;
  "network.http.speculative-parallel-limit" = 0;
  "browser.urlbar.speculativeConnect.enabled" = false;
  "browser.places.speculativeConnect.enabled" = false;

  #--------------------------------------------------------------------#
  #-- Privacy & Security (Securefox + Arkenfox)
  #--------------------------------------------------------------------#

  #--- Fingerprinting Protection
  # Base set covers canvas randomization; granularOverrides extends to WebGL, screen, fonts, concurrency
  # Keys must be firstPartyDomain/thirdPartyDomain — wrong names silently drop the override
  "privacy.fingerprintingProtection" = true;
  "privacy.fingerprintingProtection.granularOverrides" = ''[{"overrides":"+AllTargets","firstPartyDomain":"*","thirdPartyDomain":"*"}]'';

  #--- Hardware Concurrency Spoofing (real value 8 is 2+ identifying bits)
  "dom.maxHardwareConcurrency" = 2;

  #--- Tracking Protection
  "browser.contentblocking.category" = "strict";
  "privacy.globalprivacycontrol.enabled" = true;
  "privacy.globalprivacycontrol.functionality.enabled" = true;
  "privacy.antitracking.isolateContentScriptResources" = true;
  "privacy.trackingprotection.allow_list.baseline.enabled" = true;
  "privacy.trackingprotection.allow_list.convenience.enabled" = true;
  "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com";
  "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com, *.twimg.com";
  "network.cookie.sameSite.noneRequiresSecure" = true;

  #--- Certificate & Connection Security
  "security.OCSP.enabled" = 0;
  "security.remote_settings.crlite_filters.enabled" = true;
  "security.pki.crlite_mode" = 2;
  "security.cert_pinning.enforcement_level" = 2;
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  "security.csp.reporting.enabled" = false;
  "security.webauthn.always_allow_direct_attestation" = false;
  "browser.xul.error_pages.expert_bad_cert" = true;
  "security.tls.enable_0rtt_data" = false;

  #--- HTTPS
  "dom.security.https_first" = true;
  "dom.security.https_only_mode_send_http_background_request" = false;

  #--- DNS over HTTPS (Maximum Protection)
  # Mullvad's public DoH works with and without VPN active — no conflict
  # Mode 3 = DoH only, no plaintext fallback
  "network.trr.mode" = 3;
  "network.trr.uri" = "https://extended.dns.mullvad.net/dns-query";
  "network.trr.custom_uri" = "https://extended.dns.mullvad.net/dns-query";

  #--- Network Hardening
  "network.proxy.socks_remote_dns" = true;
  "network.file.disable_unc_paths" = true;
  "network.gio.supported-protocols" = "";

  #--- Geolocation
  "geo.provider.use_geoclue" = false;

  #--- Disk Avoidance & Sanitizing
  "browser.cache.disk.enable" = false;
  "browser.sessionstore.privacy_level" = 2;
  "browser.shell.shortcutFavicons" = false;
  "browser.download.start_downloads_in_tmp_dir" = true;
  "browser.download.manager.addToRecentDocs" = false;
  "browser.helperApps.deleteTempFileOnExit" = true;
  "browser.privatebrowsing.forceMediaMemoryCache" = true;
  "browser.privatebrowsing.resetPBM.enabled" = true;
  "browser.sessionstore.interval" = 60000;
  "privacy.history.custom" = true;

  #--- Search & URL Bar Privacy
  "browser.search.separatePrivateDefault" = true;
  "browser.search.separatePrivateDefault.ui.enabled" = true;
  "browser.search.suggest.enabled" = false;
  "browser.search.update" = false;
  "browser.urlbar.update2.engineAliasRefresh" = true;
  "browser.urlbar.suggest.quicksuggest.sponsored" = false;
  "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
  "browser.urlbar.quicksuggest.enabled" = false;
  "browser.urlbar.suggest.searches" = false;
  "browser.urlbar.showSearchTerms.enabled" = false;
  "browser.urlbar.trending.featureGate" = false;
  "browser.urlbar.addons.featureGate" = false;
  "browser.urlbar.amp.featureGate" = false;
  "browser.urlbar.importantDates.featureGate" = false;
  "browser.urlbar.market.featureGate" = false;
  "browser.urlbar.mdn.featureGate" = false;
  "browser.urlbar.weather.featureGate" = false;
  "browser.urlbar.wikipedia.featureGate" = false;
  "browser.urlbar.yelp.featureGate" = false;
  "browser.urlbar.yelpRealtime.featureGate" = false;
  "browser.formfill.enable" = false;
  "security.insecure_connection_text.enabled" = true;
  "security.insecure_connection_text.pbmode.enabled" = true;
  "network.IDN_show_punycode" = true;

  #--- Password & Form Autofill
  "signon.rememberSignons" = false;
  "signon.autofillForms" = false;
  "signon.formlessCapture.enabled" = false;
  "signon.privateBrowsingCapture.enabled" = false;
  "network.auth.subresource-http-auth-allow" = 1;
  "editor.truncate_user_pastes" = false;
  "extensions.formautofill.addresses.enabled" = false;
  "extensions.formautofill.creditCards.enabled" = false;

  #--- Mixed Content & Cross-Site Protection
  "security.mixed_content.block_display_content" = true;
  "security.mixed_content.upgrade_display_content" = true;
  "security.mixed_content.upgrade_display_content.image" = true;
  "pdfjs.enableScripting" = false;
  "extensions.postDownloadThirdPartyPrompt" = false;

  #--- Headers / Referers
  "network.http.referer.XOriginTrimmingPolicy" = 2;

  #--- Containers
  "privacy.userContext.enabled" = true;
  "privacy.userContext.ui.enabled" = true;

  #--- WebRTC
  "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
  "media.peerconnection.ice.default_address_only" = true;

  #--- Safe Browsing
  "browser.safebrowsing.downloads.remote.enabled" = false;

  #--- Browser Hardening
  "browser.uitour.enabled" = false;
  "devtools.debugger.remote-enabled" = false;
  "browser.tabs.searchclipboardfor.middleclick" = false;
  "browser.contentanalysis.enabled" = false;
  "browser.contentanalysis.default_result" = 0;
  "extensions.enabledScopes" = 5;
  "dom.disable_window_move_resize" = true;
  "browser.startup.homepage_override.mstone" = "ignore";
  "privacy.spoof_english" = 1;

  #--------------------------------------------------------------------#
  #-- Telemetry & Mozilla Services
  #--------------------------------------------------------------------#

  #--- Mozilla Services (Notifications, Geolocation, Accounts)
  "permissions.default.desktop-notification" = 2;
  "permissions.default.geo" = 2;
  "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";
  "permissions.manager.defaultsUrl" = "";
  "webchannel.allowObject.urlWhitelist" = "";
  "identity.fxaccounts.enabled" = true;
  "dom.push.enabled" = false;
  "dom.push.connection.enabled" = false;

  #--- New Tab Sponsored Content
  "browser.newtabpage.activity-stream.showSponsored" = false;
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
  "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
  "browser.newtabpage.activity-stream.default.sites" = "";
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;

  #--- Extension Discovery
  "extensions.getAddons.showPane" = false;
  "extensions.getAddons.cache.enabled" = false;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "extensions.webcompat-reporter.enabled" = false;
  "browser.discovery.enabled" = false;

  #--- Telemetry
  "datareporting.policy.dataSubmissionEnabled" = false;
  "datareporting.healthreport.uploadEnabled" = false;
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  "toolkit.telemetry.updatePing.enabled" = false;
  "toolkit.telemetry.bhrPing.enabled" = false;
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  "toolkit.telemetry.coverage.opt-out" = true;
  "toolkit.coverage.opt-out" = true;
  "toolkit.coverage.endpoint.base" = "";
  "browser.ping-centre.telemetry" = false;
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry" = false;
  "datareporting.usage.uploadEnabled" = false;

  #--- Experiments & Studies
  "app.shield.optoutstudies.enabled" = false;
  "app.normandy.enabled" = false;
  "app.normandy.api_url" = "";

  #--- Crash Reports
  "breakpad.reportURL" = "";
  "browser.tabs.crashReporting.sendReport" = false;
  "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

  #--- Captive Portal & Connectivity Checks
  "captivedetect.canonicalURL" = "";
  "network.captive-portal-service.enabled" = false;
  "network.connectivity-service.enabled" = false;

  #--------------------------------------------------------------------#
  #-- Miscellaneous
  #--------------------------------------------------------------------#

  #--- Firefox AI / ML (FF128+ ships on-device ML features that phone home)
  "browser.ai.control.default" = "blocked";
  "browser.ml.enable" = false;
  "browser.ml.chat.enabled" = false;
  "browser.ml.chat.menu" = false;
  "browser.ml.linkPreview.enabled" = false;
  "browser.tabs.groups.smart.enabled" = false;

  #--- Fullscreen
  "full-screen-api.transition-duration.enter" = "0 0";
  "full-screen-api.transition-duration.leave" = "0 0";
  "full-screen-api.warning.timeout" = 0;

  #--- New Tab Cleanup
  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
  "browser.aboutwelcome.enabled" = false;

  #--- userChrome / userContent CSS support
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

  #--- Experimental Features
  "layout.css.grid-template-masonry-value.enabled" = true;
  "dom.enable_web_task_scheduling" = true;
  "layout.css.has-selector.enabled" = true;
  "dom.security.sanitizer.enabled" = true;

  #--- Language
  "intl.accept_languages" = "en-US, en";

  #--- Other
  "content.notify.interval" = 100000;
  "dom.battery.enabled" = false;
}
