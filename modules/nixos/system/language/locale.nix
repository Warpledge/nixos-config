#=====================================================================#
# SYSTEM LOCALE CONFIGURATION (TIMEZONE, I18N, LOCALES)
#=====================================================================#
#- Values come from the machine's settings.nix (timeZone, locale, consoleKeyMap)
{
  lib,
  machine,
  ...
}: {
  #--- Timezone
  time.timeZone = machine.timeZone;

  #--- Localization Settings
  i18n = {
    defaultLocale = machine.locale;
    extraLocaleSettings = {
      LC_ADDRESS = machine.locale;
      LC_IDENTIFICATION = machine.locale;
      LC_MEASUREMENT = machine.locale;
      LC_MONETARY = machine.locale;
      LC_NAME = machine.locale;
      LC_NUMERIC = machine.locale;
      LC_PAPER = machine.locale;
      LC_TELEPHONE = machine.locale;
      LC_TIME = machine.locale;
    };
    supportedLocales = lib.unique [
      "${machine.locale}/UTF-8"
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8" # Japanese locale for CJK support
    ];
  };

  #--- Console Settings
  console.keyMap = machine.consoleKeyMap;
}
