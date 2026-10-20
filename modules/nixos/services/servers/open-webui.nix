#=====================================================================#
# OPEN WEBUI - CHAT WITH THE LOCAL MODELS
#=====================================================================#
#- A browser chat app over llama-swap (home/programs/ai/llama-swap.nix),
#- which it reaches on 127.0.0.1:8090. Listens on localhost only.
{
  lib,
  machine,
  ...
}: let
  port = 8091; # 8080, the default, is taken by Steam's webhelper
in {
  #--------------------------------------------------------------------#
  #-- Service
  #--------------------------------------------------------------------#
  services.open-webui = {
    enable = true;
    inherit port;
    # Replaces the module's default set, so its three no-tracking values are restated
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      OPENAI_API_BASE_URL = "http://127.0.0.1:8090/v1";
      OPENAI_API_KEY = "none"; # llama-swap takes no key, but the field can't be empty
      ENABLE_OLLAMA_API = "False";
      WEBUI_AUTH = "False"; # One local user, so no login page
    };
  };

  #--------------------------------------------------------------------#
  #-- Launcher
  #--------------------------------------------------------------------#
  home-manager.users = lib.mapAttrs (_: user:
    lib.mkIf user.openWebui.enable {
      xdg.desktopEntries.open-webui = {
        name = "Open WebUI";
        comment = "Chat with the local models";
        exec = "xdg-open http://127.0.0.1:${toString port}";
        icon = "internet-chat";
        categories = ["Network" "Chat"];
      };
    })
  machine.users;
}
