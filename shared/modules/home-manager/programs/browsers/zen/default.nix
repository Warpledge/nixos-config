#=====================================================================#
# ZEN BROWSER CONFIGURATION
#=====================================================================#
{
  inputs,
  username,
  ...
}: {
  imports = [inputs.zen-browser.homeModules.default];

  programs.zen-browser = {
    enable = true;

    policies = import ./policies.nix;

    #--------------------------------------------------------------------#
    #-- Default Profile
    #--------------------------------------------------------------------#
    profiles."default" = {
      id = 0;
      name = "${username}";
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

      #--- Import theme configuration
      inherit (import ./theme.nix) userChrome userContent;
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
        if [ -f "$profilesIniPath" ]; then
          if ! grep -q "^Path=default$" "$profilesIniPath"; then
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
        fi

        #--- user.js (settings & hardening prefs)
        mkdir -p "$zenProfile"
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
}
