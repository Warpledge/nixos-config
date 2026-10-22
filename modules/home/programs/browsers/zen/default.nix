#=====================================================================#
# ZEN BROWSER CONFIGURATION
#=====================================================================#
{
  config,
  inputs,
  ...
}: {
  programs.zen-browser = {
    enable = true;

    policies = import ./policies.nix;

    #--------------------------------------------------------------------#
    #-- Default Profile
    #--------------------------------------------------------------------#
    profiles."default" = {
      id = 0;
      name = config.home.username;
      isDefault = true;

      #--- Settings
      settings = (import ./settings.nix) // (import ./ui.nix);

      #--- Search Engine
      search = {
        force = true;
        default = "Brave";
        privateDefault = "Brave";
        engines = {
          "Brave" = {
            urls = [{template = "https://search.brave.com/search?q={searchTerms}";}];
            definedAliases = ["@brave"];
          };
        };
      };
    };
  };

  #=====================================================================#
  # FIX ZEN PROFILE PATHS
  # home-manager writes to ~/.config/zen/default/ but Zen reads from
  # ~/.zen/default/ — link user.js and chrome CSS to the active profile
  #=====================================================================#
  home.activation.fixZenProfile = ''
        zenProfile="$HOME/.zen/default"
        hmProfile="$HOME/.config/zen/default"

        #--- profiles.ini
        profilesIniPath="$HOME/.zen/profiles.ini"
        mkdir -p "$zenProfile"
        if ! grep -qs "^Path=default$" "$profilesIniPath"; then
            $DRY_RUN_CMD cat > "$profilesIniPath" << 'EOF'
    [Profile0]
    Name=default
    IsRelative=1
    Path=default
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
    EOF
            echo "✓ Fixed Zen Browser profiles.ini"
        fi

        #--- user.js (settings & hardening prefs)
        if [ -L "$hmProfile/user.js" ] || [ -f "$hmProfile/user.js" ]; then
          $DRY_RUN_CMD ln -sf "$hmProfile/user.js" "$zenProfile/user.js"
          echo "✓ Linked Zen user.js"
        fi

        #--- search.json.mozlz4 (search engine config)
        if [ -L "$hmProfile/search.json.mozlz4" ] || [ -f "$hmProfile/search.json.mozlz4" ]; then
          $DRY_RUN_CMD ln -sf "$hmProfile/search.json.mozlz4" "$zenProfile/search.json.mozlz4"
          echo "✓ Linked Zen search.json.mozlz4"
        fi

        #--- chrome/userChrome.css and chrome/userContent.css
        mkdir -p "$zenProfile/chrome"
        for cssFile in userChrome.css userContent.css; do
          if [ -f "$hmProfile/chrome/$cssFile" ]; then
            $DRY_RUN_CMD ln -sf "$hmProfile/chrome/$cssFile" "$zenProfile/chrome/$cssFile"
            echo "✓ Linked Zen $cssFile"
          fi
        done
  '';

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [inputs.zen-browser.homeModules.default ./theme.nix];
}
