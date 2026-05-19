#=====================================================================#
# ZEN BROWSER POLICIES (PRIVACY & SECURITY)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Privacy & Security Policies
  #--------------------------------------------------------------------#
  DisableAppUpdate = true;
  DisableTelemetry = true;
  DisableFeedbackCommands = true;
  DisableFirefoxStudies = true;
  DisablePocket = true;
  DontCheckDefaultBrowser = true;
  NoDefaultBookmarks = true;
  OfferToSaveLogins = false;

  EnableTrackingProtection = {
    Value = true;
    Locked = true;
    Cryptomining = true;
    Fingerprinting = true;
  };

  HttpsOnlyMode = "force";

  DNSOverHTTPS = {
    Enabled = true;
    ProviderURL = "https://extended.dns.mullvad.net/dns-query";
    Locked = true;
  };

  SanitizeOnShutdown = {
    Cookies = false; # true = deletes cookies and site data (will log you out of sites)
    History = false; # true = clears browsing history and open tabs state
    Cache = true; # true = clears temporary cached files and pages
  };

  PasswordManagerEnabled = false;
  DisableSetDesktopBackground = true;
  DisableThirdPartyModuleBlocking = false;
  SkipTermsOfUse = true;
  OverrideFirstRunPage = "";
}
