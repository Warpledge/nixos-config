#=====================================================================#
# LOCAL AI (FLOW Z13)
#=====================================================================#
#- Ky's opencode agents and the extras around the config's llama-swap
#- (modules/home/programs/ai/llama-swap.nix, enabled by users.kylerj's
#- llamaSwap.enable). The models and their llama.cpp flags live in
#- ../../settings.nix's localModels block; Open WebUI reaches the server
#- on 127.0.0.1:8090.
{
  config,
  lib,
  pkgs,
  ...
}: let
  main = "qwen3_8-flash-next"; # opencode's agents and their subagents
  #--- The primary engine: Halogen serves Qwen3.8 Flash Next from a container
  #--- (see local-ai-models.md). It holds ~95 GB while it runs, so
  #--- `halogen-toggle` stops it to free that for games.
  halogenModel = "halogen/halogen-qwen3.8-flash-next";
  modelsDir = "${config.home.homeDirectory}/halogen-models";

  #--- The container the service runs. KV8 halves the KV pool's memory so more
  #--- of the 47.7 GiB lookup table stays in the page cache; the disk cache
  #--- keeps a conversation's prompt across a restart
  halogenRun = pkgs.writeShellScript "halogen-run" ''
    # The docker daemon may still be starting when a session logs in
    for _ in $(seq 1 60); do
      ${pkgs.docker}/bin/docker info >/dev/null 2>&1 && break
      sleep 2
    done
    exec ${pkgs.docker}/bin/docker run --rm --name halogen \
      -u "$(id -u):$(id -g)" \
      -p 127.0.0.1:8731:8731 \
      --device /dev/kfd --device /dev/dri \
      --group-add "$(${pkgs.coreutils}/bin/stat -c %g /dev/kfd)" \
      --group-add "$(${pkgs.coreutils}/bin/stat -c %g /dev/dri/renderD128)" \
      --ipc=host --ulimit memlock=-1:-1 \
      -e HALOGEN_KV8=1 \
      -e HALOGEN_KV_POOL_POSITIONS=262144 \
      -e HALOGEN_REASONING_EFFORT=medium \
      -e HALOGEN_VISION_TOWER=/models/qwen38-flash-next-vision.hgn \
      -e HALOGEN_CACHE_DIR=/cache \
      -v ${modelsDir}:/models -v ${modelsDir}/halogen-cache:/cache \
      ghcr.io/peonist-ai/halogen-flash-server:0.20.7
  '';

  #--- While this file exists, ask-claude runs without asking Ky first
  autoFlag = "${config.xdg.stateHome}/ask-claude/auto";

  #--- ~/nixos-config's top level, and Ky's own folders inside it
  nixosConfig = "${config.home.homeDirectory}/nixos-config";
  # Listed by name: `*` also matches `/`, so "*.md" would catch other projects' files
  shared = [
    "AGENTS.md"
    "CLAUDE.md"
    "README.md"
    "LICENSE"
    "flake.nix"
    "flake.lock"
    "setup.sh"
    "pyrightconfig.json"
    ".gitignore"
    ".claude/*"
    "docs/*"
    "lib/*"
    "machines/*"
    "modules/*"
    "users/*"
  ];
  own = ["machines/activenixtab/*" "users/kylerj/*"];
in {
  #--------------------------------------------------------------------#
  #-- OpenCode: agents around the llama-swap models
  #--------------------------------------------------------------------#
  #--- opencode merges opencode.json from every folder above the one it starts in,
  #--- so this one file makes `gamedev` the default agent in each project under
  #--- ~/Projects (Tab switches to `system`)
  home.file."Projects/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    default_agent = "gamedev";
  };

  #--- Ky's two models take images; the config's provider entry has no
  #--- `modalities`, so opencode would hide the image picker
  programs.opencode.settings.provider.llama-swap.models =
    lib.genAttrs
    [
      "qwen3_8-flash-next"
      "qwen3_8-flash-next-instruct"
      "nemotron-3_5-super-vl"
      "nemotron-3_5-super-vl-instruct"
    ]
    (_: {
      modalities = {
        input = ["text" "image"];
        output = ["text"];
      };
      # Measured picks: opencode compacts context.output before it, so these
      # set where that happens (~245K on the 256K model, ~48K on the 64K one)
      limit.output = lib.mkForce 16384;
    });

  #--- Halogen: the primary engine, one model and no aliases; its reasoning
  #--- effort is fixed on the server (HALOGEN_REASONING_EFFORT)
  programs.opencode.settings.provider.halogen = {
    npm = "@ai-sdk/openai-compatible";
    name = "Halogen";
    options.baseURL = "http://127.0.0.1:8731/v1";
    models."halogen-qwen3.8-flash-next" = {
      name = "Qwen3.8 Flash Next (Halogen)";
      limit = {
        context = 262144;
        output = 16384;
      };
      modalities = {
        input = ["text" "image"];
        output = ["text"];
      };
    };
  };

  programs.opencode.settings = {
    #--- Halogen is primary; llama-swap's Nemotron stays pickable by hand in
    #--- /model (nothing loads it until a request names it)
    model = lib.mkForce halogenModel;
    small_model = lib.mkForce halogenModel;
    #--- Two primary agents (Tab switches): `system` for this computer, the default,
    #--- and `gamedev` for the game projects under ~/Projects, which
    #--- ~/Projects/opencode.json picks. They edit files themselves and start
    #--- subagents only when it helps or a skill calls for one.
    #--- The subagents they start run on the workers' alias
    default_agent = "system";
    # Only Ky switches the ask-claude approval off. Edits to Warpledge's shared
    # files ask Ky first: paths are relative inside ~/nixos-config, absolute from
    # another project. The last matching rule wins
    permissions =
      [
        {
          action = "shell";
          resource = "ask-claude-auto*";
          effect = "deny";
        }
      ]
      ++ map (resource: {
        action = "edit";
        inherit resource;
        effect = "ask";
      }) (shared ++ map (p: "${nixosConfig}/${p}") shared)
      ++ map (resource: {
        action = "edit";
        inherit resource;
        effect = "allow";
      }) (own ++ map (p: "${nixosConfig}/${p}") own);
    # v2's `agents`: with `permissions` above the file is read as v2, which drops a
    # v1 `agent` entry's `permission`
    agents = let
      # What stays with Ky: git state changes and garbage collection. opencode
      # checks each part of a compound command on its own
      base = {
        mode = "primary";
        model = halogenModel;
        permissions =
          map (resource: {
            action = "shell";
            inherit resource;
            effect = "deny";
          }) [
            "git checkout *"
            "git restore *"
            "git reset *"
            "git clean *"
            "git config *"
            "git remote *"
            "git push*"
            "nix store gc*"
            "nix-collect-garbage*"
          ];
      };
    in
      lib.genAttrs ["general" "explore"] (_: {
        # Halogen has no `-instruct` alias: one model, one server
        model = halogenModel;
      })
      // {
        system =
          base
          // {
            description = "Answers questions about this computer and fixes its errors";
            # With this machine's and Ky's notes; AGENTS.md loads from the repo itself
            system = lib.concatMapStringsSep "\n\n" builtins.readFile [
              ./agents/system.md
              ../CLAUDE.md
              ../../../users/kylerj/CLAUDE.md
            ];
          };
        gamedev =
          base
          // {
            description = "Works on a Godot game in ~/Projects";
            system = builtins.readFile ./agents/gamedev.md;
          };
      };
  };

  #--------------------------------------------------------------------#
  #-- Halogen: the service behind the agents
  #--------------------------------------------------------------------#
  #--- Boots with the session. It holds ~95 GB while running (that is the
  #--- engine's design: weights and KV resident), so Mod+Shift+H stops it when
  #--- a game needs the memory and starts it again
  systemd.user.services.halogen = {
    Unit.Description = "Halogen local LLM server (Qwen3.8 Flash Next)";
    Install.WantedBy = ["default.target"];
    Service = {
      ExecStartPre = [
        "${pkgs.coreutils}/bin/install -d ${modelsDir}/halogen-cache"
        "-${pkgs.docker}/bin/docker rm -f halogen"
      ];
      ExecStart = halogenRun;
      ExecStop = "${pkgs.docker}/bin/docker stop halogen";
      TimeoutStartSec = "300";
      Restart = "no";
    };
  };

  #--------------------------------------------------------------------#
  #-- Extras
  #--------------------------------------------------------------------#
  #--- opencode in a window; it reads the same settings as the terminal one.
  #--- ask-claude: the agents' last resort, a one-off read-only Claude Code
  #--- run in the current folder that prints its answer. Each call waits for Ky's
  #--- answer in a notification unless ask-claude-auto has switched that off
  home.packages = [
    pkgs.opencode-desktop
    #--- `halogen-toggle`: stops the engine to free its ~95 GB, starts it again
    (pkgs.writeShellScriptBin "halogen-toggle" ''
      if systemctl --user is-active --quiet halogen.service; then
        systemctl --user stop halogen.service
        ${lib.getExe pkgs.libnotify} -a halogen "Halogen stopped" "~95 GB freed"
      else
        systemctl --user start halogen.service
        ${lib.getExe pkgs.libnotify} -a halogen "Halogen starting" "first token after ~30 s"
      fi
    '')
    (pkgs.writeShellScriptBin "ask-claude" ''
      if [ $# -eq 0 ]; then
        echo 'usage: ask-claude "<self-contained question>"' >&2
        exit 2
      fi
      flag=${autoFlag}
      if [ ! -e "$flag" ]; then
        # The notification takes markup, so the question's own <, > and & are escaped
        q="$*"
        body=$(printf '%s\n\n%s' "$PWD" "''${q:0:400}" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
        choice=$(${lib.getExe pkgs.libnotify} -u critical -a "ask-claude" \
          -A allow="Allow once" -A auto="Allow until turned off" -A deny="Deny" \
          "An agent wants to ask Claude" "$body")
        case $choice in
          allow) ;;
          auto) mkdir -p "$(dirname "$flag")" && touch "$flag" ;;
          *)
            echo "Ky declined this Claude call. Don't ask Claude again for this problem;" >&2
            echo "tell Ky where you are stuck instead." >&2
            exit 1
            ;;
        esac
      fi
      exec claude -p --permission-mode plan --no-session-persistence "$*"
    '')
    #--- `ask-claude-auto on|off`, or no argument to show the state
    (pkgs.writeShellScriptBin "ask-claude-auto" ''
      flag=${autoFlag}
      case $1 in
        on) mkdir -p "$(dirname "$flag")" && touch "$flag" ;;
        off) rm -f "$flag" ;;
        "") ;;
        *)
          echo "usage: ask-claude-auto [on|off]" >&2
          exit 2
          ;;
      esac
      if [ -e "$flag" ]; then
        echo "on: ask-claude runs without asking"
      else
        echo "off: each ask-claude call asks Ky first"
      fi
    '')
  ];
}
