#=====================================================================#
# SYSTEM LOCALE CONFIGURATION (TIMEZONE, I18N, LOCALES)
#=====================================================================#
{
  #--- Timezone
  time.timeZone = "America/Chicago";

  #--- Localization Settings
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
    supportedLocales = [
      "en_US.UTF-8/UTF-8" # English US locale
      "ja_JP.UTF-8/UTF-8" # Japanese locale for CJK support
    ];
  };

  #--- Console Settings
  console.keyMap = "us"; # US keyboard layout on console
}
