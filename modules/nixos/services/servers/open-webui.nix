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
  pkgs,
  machine,
  ...
}: let
  port = 8091; # 8080, the default, is taken by Steam's webhelper
  url = "http://127.0.0.1:${toString port}";
  nixosMcpPort = 8092;

  #--- Its grey scale from Stylix's palette, for the dark theme; the steps
  #--- between Crust and Text that base16 lacks are mixed from the two
  css = with config.lib.stylix.colors.withHashtag; let
    mix = pct: "color-mix(in oklch, ${base05} ${toString pct}%, ${base00})";
  in ''
    html.dark {
      --color-gray-50: ${base05};
      --color-gray-100: ${base05};
      --color-gray-200: ${mix 88};
      --color-gray-300: ${mix 78};
      --color-gray-400: ${mix 66};
      --color-gray-500: ${mix 54};
      --color-gray-600: ${base04};
      --color-gray-700: ${base03};
      --color-gray-800: ${base02};
      --color-gray-850: color-mix(in oklch, ${base02} 50%, ${base01});
      --color-gray-900: ${base01};
      --color-gray-950: ${base00};
    }
    html.dark ::selection {
      background: color-mix(in oklch, ${base0E} 40%, transparent);
    }
  '';

  #--- The server copies the frontend's static/ to its state dir on each start, and
  #--- every page loads static/custom.css, so the theme rides in a frontend copy
  frontend = "${pkgs.open-webui.frontend}/share/open-webui";
  themedFrontend = pkgs.runCommand "open-webui-frontend-stylix" {nativeBuildInputs = [pkgs.lndir];} ''
    mkdir $out
    lndir -silent ${frontend} $out
    rm -f $out/static/custom.css
    cp ${pkgs.writeText "custom.css" css} $out/static/custom.css
  '';

  #--- MCP servers it calls itself; only Streamable HTTP ones work without a proxy.
  #--- Same servers as home/programs/ai/mcp.nix
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
    package = pkgs.open-webui.overridePythonAttrs {
      makeWrapperArgs = ["--set FRONTEND_BUILD_DIR ${themedFrontend}"];
    };
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
        (mcp "nixos" "NixOS" "http://127.0.0.1:${toString nixosMcpPort}/mcp")
      ];
    };
  };

  #--------------------------------------------------------------------#
  #-- NixOS MCP Server
  #--------------------------------------------------------------------#
  #--- mcp-nixos over HTTP on localhost: packages, options and the NixOS wiki
  systemd.services.mcp-nixos = {
    description = "mcp-nixos MCP server for Open WebUI";
    wantedBy = ["multi-user.target"];
    before = ["open-webui.service"];
    environment = {
      MCP_NIXOS_TRANSPORT = "http";
      MCP_NIXOS_HOST = "127.0.0.1";
      MCP_NIXOS_PORT = toString nixosMcpPort;
    };
    serviceConfig = {
      ExecStart = lib.getExe pkgs.mcp-nixos;
      DynamicUser = true;
      Restart = "on-failure";
      ProtectHome = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
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
        icon = "${frontend}/static/favicon.png";
        categories = ["Network" "Chat"];
      };
    })
  machine.users;
}
