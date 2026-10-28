#=====================================================================#
# LOCAL AI (FLOW Z13)
#=====================================================================#
#- llama-swap on the Radeon 8060S with models sized for 128 GB of shared
#- memory, in place of the config's llamaSwap (tuned for a 16 GB card).
#- Open WebUI (openWebui.enable) reaches it on 127.0.0.1:8090.
{
  config,
  lib,
  pkgs,
  ...
}: let
  port = 8090; # Open WebUI's address for llama-swap

  #--- 0.7.0 adds Nemotron 3.5 Super VL; nixpkgs is on 0.6.0, whose one patch
  #--- 0.7.0 already has. Drop this once nixpkgs reaches 0.7.0
  llamaCpp = pkgs.llama-cpp-vulkan.overrideAttrs {
    version = "0.7.0";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "v0.7.0";
      hash = "sha256-pEDYgI3AMTU+cekvRX7NNt5wddznydQSNuerswvEpsA=";
    };
    patches = [];
    # 0.7.0's test-download-model fetches from Hugging Face, which the sandbox blocks
    doCheck = false;
    npmDepsHash = "sha256-hqYzdp1FwPhYkBP278fQXgY9NCKB6Q3P6Gko7BfP0m0=";
  };

  #--- Finds a download in its LM Studio folder, whatever the file's exact name;
  #--- the first part of a split file sorts first
  launch = pkgs.writeShellScript "llama-model" ''
    dir="${config.home.homeDirectory}/.lmstudio/models/$1" match=$2
    shift 2
    file=$(find "$dir" -maxdepth 2 -iname "$match" 2>/dev/null | sort | head -n 1)
    if [ -z "$file" ]; then
      echo "No $match in $dir: download it in LM Studio" >&2
      exit 1
    fi
    exec ${lib.getExe' llamaCpp "llama-server"} -m "$file" "$@"
  '';

  modelsDir = "${config.home.homeDirectory}/.lmstudio/models";

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

  #--- Whole model on the GPU: shared memory leaves no reason to keep experts on the CPU
  #--- Both take images through their mmproj file (`--mmproj`)
  main = "qwen3_8-flash-next"; # opencode's coordinators and workers
  models = {
    #--- opencode's default: the coordinator plus 2 subagents, one slot each. MoE, 6B
    #--- active; UD-IQ3_XXS takes 59 GB GPU memory plus 27 GB in the server process
    #--- with 2 slots, inside the 90 GB budget. Results: ../local-ai-models.md
    qwen3_8-flash-next = {
      name = "Qwen3.8 Flash Next";
      dir = "unsloth/Qwen3.8-Flash-Next-GGUF";
      match = "Qwen3.8-Flash-Next-UD-IQ3_XXS-00001-of-*.gguf";
      context = 65536;
      # opencode compacts at this less `output`, near 48K
      output = 16384;
      slots = 3;
      # q8_0 V cache: ~17% faster prompts at 32K, perplexity within error
      flags = [
        "-ctv q8_0"
        "--mmproj '${modelsDir}/unsloth/Qwen3.8-Flash-Next-GGUF/mmproj-F16.gguf'"
      ];
      #--- Coordinator: Qwen's thinking sampling at medium effort. The template's
      #--- default, xhigh, overthinks: it ran out of a 12K budget on small tasks
      params = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 20;
        min_p = 0;
        presence_penalty = 0.0;
        chat_template_kwargs.reasoning_effort = "medium";
      };
      #--- Workers (the -instruct alias): the same; at low effort it edited directly
      fast = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 20;
        min_p = 0;
        presence_penalty = 0.0;
        chat_template_kwargs.reasoning_effort = "medium";
      };
    };
    #--- Fits 80 GB: the coordinator plus 2 parallel subagents, one slot each.
    #--- MoE with Mamba layers, 12B active; ~72 GB loaded. Tuning and test results
    #--- are in ../local-ai-models.md
    nemotron-3_5-super-vl = {
      name = "Nemotron 3.5 Super VL";
      dir = "unsloth/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-GGUF";
      match = "NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-UD-Q3_K_XL-00001-of-*.gguf";
      context = 65536;
      # opencode compacts at this less `output`, near 48K
      output = 16384;
      slots = 3;
      # MTP drafting: 28 tok/s alone and 29 with two requests, against 19 and 26 without
      flags = [
        "--spec-type draft-mtp"
        "--top-k 0 --min-p 0"
        "--mmproj '${modelsDir}/unsloth/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-GGUF/mmproj-BF16.gguf'"
      ];
      #--- Coordinator: full reasoning, NVIDIA's sampling
      params = {
        temperature = 1.0;
        top_p = 0.95;
        chat_template_kwargs.enable_thinking = true;
      };
      #--- Workers (the -instruct alias): medium effort, ~3x fewer thinking tokens
      fast = {
        temperature = 1.0;
        top_p = 0.95;
        chat_template_kwargs = {
          enable_thinking = true;
          medium_effort = true;
        };
      };
    };
  };

  settings = {
    models =
      lib.mapAttrs (id: m: {
        ttl = 600; # Unloads after 10 idle minutes
        cmd = lib.concatStringsSep " " ([
            launch
            "'${m.dir}'"
            "'${m.match}'"
            "--port \${PORT}"
            # Several slots share one cache pool of `slots` x `context`
            (
              if m.slots == 1
              then "-c ${toString m.context} -np 1"
              else "-np ${toString m.slots} -kvu --kv-unified-per-slot ${toString m.context}"
            )
            "-fa on -ngl 99 --load-mode none -ub 2048 --no-webui"
            "-ctk f16 -ctv f16"
          ]
          ++ m.flags);
        # The -instruct key also registers as an alias of the same loaded model
        filters.setParamsByID =
          {${id} = m.params;}
          // lib.optionalAttrs (m.fast != null) {"${id}-instruct" = m.fast;};
      })
      models;
    #--- One model loaded at a time
    groups.gpu = {
      swap = true;
      exclusive = true;
      members = lib.attrNames models;
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Service
  #--------------------------------------------------------------------#
  systemd.user.services.llama-swap = {
    Unit.Description = "llama-swap local LLM server";
    Install.WantedBy = ["default.target"];
    Service = {
      ExecStart = "${lib.getExe pkgs.llama-swap} -listen 127.0.0.1:${toString port} -config ${(pkgs.formats.yaml {}).generate "llama-swap.yaml" settings}";
      Restart = "on-failure";
    };
  };

  #--------------------------------------------------------------------#
  #-- OpenCode Provider
  #--------------------------------------------------------------------#
  #--- opencode in a window; it reads the same settings as the terminal one.
  #--- ask-claude: the coordinators' last resort, a one-off read-only Claude Code
  #--- run in the current folder that prints its answer. Each call waits for Ky's
  #--- answer in a notification unless ask-claude-auto has switched that off
  home.packages = [
    pkgs.opencode-desktop
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
          "A coordinator wants to ask Claude" "$body")
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

  programs.opencode.settings = {
    model = "llama-swap/${main}";
    # Titles and summaries on the workers' alias, so the model stays loaded
    small_model = "llama-swap/${main}-instruct";
    #--- Two coordinators (Tab switches): `system` for this computer, the default,
    #--- and `gamedev` for the Godot game, which its project's opencode.json picks.
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
      # Coordinators can't edit, so changes go through the subagents
      coordinator = {
        mode = "primary";
        model = "llama-swap/${main}";
        permissions =
          [
            {
              action = "edit";
              resource = "*";
              effect = "deny";
            }
          ]
          # Shell routes to writing files, and git and GC commands that stay with
          # Ky. opencode checks each part of a compound command on its own
          ++ map (resource: {
            action = "shell";
            inherit resource;
            effect = "deny";
          }) [
            "sed -i*"
            "sed * -i*"
            "sed --in-place*"
            "sed * --in-place*"
            "perl -i*"
            "perl -pi*"
            "mv *"
            "cp *"
            "rm *"
            "tee *"
            "touch *"
            "truncate *"
            "install *"
            "ln *"
            "dd *"
            "* > *"
            "* >> *"
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
        model = "llama-swap/${main}-instruct";
      })
      // {
        system =
          coordinator
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
          coordinator
          // {
            description = "Coordinates work on the Godot game Clocked Out";
            system = builtins.readFile ./agents/gamedev.md;
          };
      };
    provider.llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options.baseURL = "http://127.0.0.1:${toString port}/v1";
      models = lib.concatMapAttrs (id: m: let
        model = name: output: {
          inherit name;
          modalities = {
            input = ["text" "image"];
            output = ["text"];
          };
          limit = {
            context = m.session or m.context;
            inherit output;
          };
        };
      in
        {${id} = model m.name (m.output or 32768);}
        // lib.optionalAttrs (m.fast != null) {
          "${id}-instruct" = model "${m.name} (fast)" (m.output or 8192);
        })
      models;
    };
  };
}
