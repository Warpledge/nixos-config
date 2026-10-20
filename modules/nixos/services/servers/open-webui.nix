#=====================================================================#
# OPEN WEBUI - CHAT WITH THE LOCAL MODELS
#=====================================================================#
#- A chat app over llama-swap (home/programs/ai/llama-swap.nix), which it
#- reaches on 127.0.0.1:8090, opened as a Helium app window. Listens on
#- localhost only. Persistent config is off, so these settings win on every
#- start and changes made in its admin panel last until the next restart.
{
  config,
  lib,
  machine,
  ...
}: let
  port = 8091; # 8080, the default, is taken by Steam's webhelper
  url = "http://127.0.0.1:${toString port}";

  #--- MCP servers it calls itself; only Streamable HTTP ones work without a proxy.
  #--- Same URLs as home/programs/ai/mcp.nix
  mcp = id: name: mcpUrl: {
    type = "mcp";
    url = mcpUrl;
    path = "";
    auth_type = "none";
    key = "";
    config.enable = true;
    info = {inherit id name;};
  };
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
      ENABLE_PERSISTENT_CONFIG = "False";
      #--- Web search through DuckDuckGo, which needs no key; results go to the
      #--- model as they are, so no embedding model is downloaded for them
      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_ENGINE = "duckduckgo";
      BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL = "True";
      TOOL_SERVER_CONNECTIONS = builtins.toJSON [
        (mcp "deepwiki" "DeepWiki" "https://mcp.deepwiki.com/mcp")
        (mcp "grep" "grep.app" "https://mcp.grep.app")
      ];
    };
  };

  #--------------------------------------------------------------------#
  #-- Launcher
  #--------------------------------------------------------------------#
  #--- A Helium app window (no tabs or address bar) for users with Helium on,
  #--- the default browser for the rest
  home-manager.users = lib.mapAttrs (_: user:
    lib.mkIf user.openWebui.enable {
      xdg.desktopEntries.open-webui = {
        name = "Open WebUI";
        comment = "Chat with the local models";
        exec =
          if user.browsers.helium
          then "helium --app=${url}"
          else "xdg-open ${url}";
        icon = "${config.services.open-webui.package.frontend}/share/open-webui/static/favicon.png";
        categories = ["Network" "Chat"];
      };
    })
  machine.users;
}
