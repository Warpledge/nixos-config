{
  pkgs,
  lib,
  config,
  user,
  ...
}: let
  #--- The models picked in localAi (lib/local-models.nix), served by ai/llama-swap.nix
  models = import ../../../../lib/local-models.nix;
  #--- Every coding model turned on; the first is the default
  codeIds = lib.optionals user.llamaSwap.enable user.localAi.code;
  codeId = lib.head codeIds;
  code =
    if codeIds != []
    then models.code.${codeId}
    else null;
  hasFast = code != null && code.fast != null;
  editId = user.localAi.edit;
  edit =
    if user.llamaSwap.enable && editId != null
    then models.edit.${editId}
    else null;

  #--- Same token file as ai/mcp.nix, read at launch so it never enters the store
  githubMcp = pkgs.writeShellScript "github-mcp" ''
    GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "$HOME/.nixos-config-mcp/github")
    export GITHUB_PERSONAL_ACCESS_TOKEN
    exec ${lib.getExe pkgs.github-mcp-server} stdio --read-only
  '';
in {
  #--------------------------------------------------------------------#
  #-- Dependencies
  #--------------------------------------------------------------------#
  home.packages = [
    #--- Nix Tooling
    pkgs.alejandra
    pkgs.nixd

    #--- Language Servers
    pkgs.typescript
    pkgs.biome
    pkgs.nil
    pkgs.rust-analyzer
    pkgs.yaml-language-server
    pkgs.vue-language-server
    pkgs.astro-language-server
    pkgs.vscode-langservers-extracted
    pkgs.marksman
    pkgs.lua-language-server

    #--- Runtime & Utilities
    pkgs.nodejs
  ];

  #--------------------------------------------------------------------#
  #-- Zed Editor Configuration
  #--------------------------------------------------------------------#
  programs.zed-editor = {
    enable = true;
    extraPackages = [pkgs.nixd];

    #--- Keybinds
    userKeymaps = [
      #--- Global bindings
      {
        bindings = {
          ctrl-q = null;
          "shift-ctrl-v" = null;
          "shift-ctrl-c" = null; # disable collaborative panel keybind
        };
      }

      #--- Editor bindings
      {
        context = "Editor";
        bindings = {
          ctrl-q = "editor::ToggleComments";
        };
      }

      #--- File panel (netrw)
      {
        context = "ProjectPanel && not_editing";
        bindings = {
          "aa" = "project_panel::NewFile";
          "AA" = "project_panel::NewDirectory";
          "rr" = "project_panel::Rename";
          "cc" = "project_panel::Copy";
          "pp" = "project_panel::Paste";
        };
      }
    ];
  };

  #--------------------------------------------------------------------#
  #-- Zed Settings (Declarative Template)
  #--------------------------------------------------------------------#
  #--- Settings template for merging with Zed's writable settings.json
  #--- Avoids making settings read-only, so AI models can be switched from GUI

  #--- A key takes the repo's value when missing, unchanged since the last rebuild,
  #--- or locked, as in wm/dms-mutable.nix; other GUI changes stay
  home.activation.zedSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    let
      #--- Extract font names from Stylix config
      uiFontFamily = config.stylix.fonts.sansSerif.name;
      bufferFontFamily = config.stylix.fonts.monospace.name;
      terminalFontFamily = config.stylix.fonts.monospace.name;
      jq = lib.getExe pkgs.jq;

      #--- Reset on every rebuild; fonts come from Stylix
      locked = builtins.toJSON [
        ["icon_theme"]
        ["ui_font_family"]
        ["buffer_font_family"]
        ["terminal" "font_family"]
      ];

      zedDeclarativeSettings = builtins.toJSON {
        #--- UI & Theme
        # DMS's matugen writes it to ~/.config/zed/themes on each theme change
        theme = "DankShell Dark";
        icon_theme = "Catppuccin Mocha";
        base_keymap = "VSCode";
        vim_mode = false;
        window_decorations = "client";
        fullscreen_mode = "native";
        accessible_mode = false;
        bottom_dock_layout = "contained";
        active_pane_modifiers = {
          border_size = 0.0;
          inactive_opacity = 1.0;
        };

        #--- Fonts (sourced from Stylix)
        ui_font_family = uiFontFamily;
        buffer_font_family = bufferFontFamily;
        ui_font_size = 17;
        agent_ui_font_size = 17;
        buffer_font_size = 16;

        buffer_font_weight = 400.0;
        ui_font_weight = 400.0;

        #--- Terminal Integration
        terminal = {
          shell = {
            program = "zsh";
          };
          starts_open = false;
          button = false;
          blinking = "off";
          font_family = terminalFontFamily;
          font_size = 15;
        };

        #--- Editor Behavior
        buffer_line_height = "comfortable";
        autosave = "on_focus_change";
        extend_comment_on_newline = false;
        confirm_quit = false;
        tab_size = 2;
        soft_wrap = "editor_width";
        cursor_blink = false;
        restore_on_startup = "last_workspace";
        cli_default_open_behavior = "existing_window";
        close_panel_on_toggle = false;
        focus_follows_mouse.enabled = false;
        preview_tabs.enabled = true;

        #--- Panels
        project_panel = {
          auto_open.on_create = true;
          sort_order = "default";
          sort_mode = "directories_first";
          hide_hidden = false;
          hide_root = true;
          drag_and_drop = false;
          indent_guides.show = "always";
          sticky_scroll = true;
          git_status_indicator = false;
          diagnostic_badges = true;
          show_diagnostics = "errors";
          scrollbar = {
            horizontal_scroll = true;
            show = "system";
          };
          bold_folder_labels = true;
          starts_open = true;
          auto_reveal_entries = true;
          indent_size = 15.0;
          git_status = true;
          folder_indicator = "chevron";
          file_icons = true;
          entry_spacing = "standard";
          hide_gitignore = false;
          title_tooltip_delay = "default";
          default_width = 250.0;
          button = true;
          auto_fold_dirs = false;
          dock = "left";
        };
        outline_panel = {
          multi_buffer_hide_symbols = false;
          indent_guides.show = "always";
          auto_fold_dirs = false;
          indent_size = 15.0;
          git_status = true;
          folder_indicator = "icon";
          file_icons = true;
          dock = "right";
        };
        git_panel = {
          show_count_badge = false;
          entry_primary_click_action = "project_diff";
          diff_stats = true;
          folder_indicator = "chevron";
          file_icons = true;
          tree_view = true;
          collapse_untracked_diff = false;
          group_by = "status";
          sort_by = "path";
          status_style = "label_color";
          button = true;
          dock = "right";
        };
        debugger = {
          dock = "bottom";
          button = false;
        };

        #--- Visual Indicators
        show_whitespaces = "selection";
        relative_line_numbers = "disabled";
        diagnostics_max_severity = "error";
        scrollbar = {
          show = "auto";
          git_diff = true;
          diagnostics = "error";
        };

        #--- Git Integration
        git = {
          enable_diff = true;
          enable_status = true;
          disable_git = false;
          git_gutter = "tracked_files";
          inline_blame = {
            enabled = true;
          };
        };

        #--- UI Elements
        collaboration_panel = {
          button = false;
        };
        middle_click_paste = false;
        tab_bar = {
          show_pinned_tabs_in_separate_row = false;
          show = true;
          show_nav_history_buttons = false;
          show_tab_bar_buttons = true;
        };
        tabs = {
          show_close_button = "hover";
          show_diagnostics = "off";
          activate_on_close = "history";
          close_position = "right";
          file_icons = true;
          git_status = true;
        };
        title_bar = {
          button_layout = "";
          show_menus = false;
          show_user_picture = true;
          show_user_menu = true;
          show_sign_in = true;
          show_onboarding_banner = true;
          show_project_items = true;
          show_worktree_name = true;
          show_branch_name = true;
          show_branch_status_icon = true;
        };
        status_bar = {
          show_active_file = false;
          pending_keystrokes_indicator = true;
          active_encoding_button = "non_utf8";
          active_language_button = true;
          cursor_position_button = false;
          line_endings_button = false;
        };
        search.button = true;
        diagnostics.button = true;

        #--- AI
        disable_ai = !(user.llamaSwap.enable || user.claude.enable);
        agent =
          {
            button = true;
            dock = "right";
            threads_sidebar.position = "right";
            thinking_display = "always_collapsed";

            # Run tools without asking unless a rule below matches, like opencode
            tool_permissions.default = "allow";
            # The rules below guard instead; the sandbox blocks .git and nix's socket
            sandbox_permissions.allow_unsandboxed = true;
            #--- Mirrors CLAUDE.md rules 1, 4, 6 and 11; applies to Claude Agent too
            tool_permissions.tools = let
              patterns = map (pattern: {inherit pattern;});
              secrets = patterns ["\\.nixos-config-mcp/" "settings\\.local\\.json$"];
              # Writable places git can't restore; file tools already stay in the project
              outside = "(~|\\$HOME|/home/|/mnt/)";
              writes = "\\b(rm|rmdir|unlink|mv|cp|ln|touch|mkdir|tee|truncate|install|rsync)\\b|\\bsed\\s+-i";
            in {
              terminal.always_deny = patterns [
                "nixm\\s+(rebuild|boot|upgrade|rollback)"
                "nixos-rebuild"
                "\\bnh\\s+os\\b"
                "\\b(sudo|pkexec|doas|run0)\\b"
                "git\\s+(push|rebase|reset\\s+--hard|clean\\s+-\\S*f)"
                "git\\s+commit\\s.*--amend"
                "\\b(dd|mkfs\\S*|wipefs|shred)\\s"
                "\\bch(mod|own)\\s+-\\S*R"
                "\\brm\\s.*\\$"
              ];
              terminal.always_confirm = patterns [
                "\\brm\\s"
                "(${writes}).*${outside}"
                "${outside}.*(${writes})"
                ">\\s*${outside}"
              ];
              delete_path.default = "confirm";
              edit_file.always_deny = secrets;
              write_file.always_deny = secrets;
            };
          }
          // lib.optionalAttrs (code != null) {
            default_model = {
              provider = "llama-swap";
              model = codeId;
            };
            # Thread titles: thinking there only delays the first reply
            thread_summary_model = {
              provider = "llama-swap";
              model =
                if hasFast
                then "${codeId}-instruct"
                else codeId;
            };
            #--- Fewer tool schemas in the local model's context
            default_profile = "local";
            profiles.local = {
              name = "Local";
              enable_all_context_servers = true;
              tools = lib.genAttrs [
                "apply_code_action"
                "copy_path"
                "create_directory"
                "delete_path"
                "diagnostics"
                "edit_file"
                "find_path"
                "find_references"
                "get_code_actions"
                "go_to_definition"
                "grep"
                "list_directory"
                "move_path"
                "read_file"
                "rename_symbol"
                "terminal"
                "write_file"
              ] (_: true);
            };
          };
        #--- Inline completions from the small model in ai/llama-swap.nix
        edit_predictions = lib.optionalAttrs (edit != null) {
          provider = "open_ai_compatible_api";
          open_ai_compatible_api = {
            api_url = "http://127.0.0.1:8090/v1/completions";
            model = editId;
            prompt_format = edit.format;
          };
        };
        #--- Claude Code in the agent panel, signed in with Claude Code's own login
        agent_servers = lib.optionalAttrs user.claude.enable {
          "Claude Code" = {
            type = "custom";
            command = lib.getExe pkgs.claude-agent-acp;
            args = [];
            env = {};
          };
        };
        #--- Local models served by ai/llama-swap.nix (same port and model ids)
        language_models = lib.optionalAttrs (code != null) {
          openai_compatible.llama-swap = {
            api_url = "http://127.0.0.1:8090/v1";
            available_models = lib.concatMap (id: let
              model = models.code.${id};
            in
              [
                {
                  name = id;
                  display_name = model.name;
                  max_tokens = model.context;
                }
              ]
              ++ lib.optional (model.fast != null) {
                name = "${id}-instruct";
                display_name = "${model.name} (fast)";
                max_tokens = model.context;
              })
            codeIds;
          };
        };

        #--- Network
        proxy = "";

        #--- Telemetry
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        #--- Extensions
        auto_install_extensions = {
          biome = true;
          catppuccin = true;
          catppuccin-icons = true;
          marksman = true;
          nu = true;
          nix = true;
          ruby = true;
          html = true;
          toml = true;
          kdl = true;
          qml = true;
          git-firefly = true;
        };

        #--- Formatting & Code Actions
        formatter = {
          language_server = {
            name = "biome";
          };
        };
        code_actions_on_format = {
          "source.fixAll.biome" = true;
          "source.organizeImports.biome" = true;
        };

        #--- Editor Enhancements
        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
        };

        #--- Language-Specific Settings
        languages = {
          Nix = {
            language_servers = ["nixd"];
            tab_size = 2;
            hard_tabs = false;
            formatter = {
              external = {
                command = "alejandra";
                arguments = ["--quiet" "--"];
              };
            };
            format_on_save = "on";
          };

          JavaScript = {
            tab_size = 2;
            formatter = {
              language_server = {name = "biome";};
            };
            code_actions_on_format = {
              "source.fixAll.biome" = true;
              "source.organizeImports.biome" = true;
            };
          };

          TypeScript = {
            tab_size = 2;
            formatter = {
              language_server = {name = "biome";};
            };
            code_actions_on_format = {
              "source.fixAll.biome" = true;
              "source.organizeImports.biome" = true;
            };
          };
        };

        #--- Language Server Protocol
        lsp = {
          nixd.settings.diagnostic.suppress = ["sema-extra-with"];
          biome.settings.linter.rules.correctness.noUnknownTypeSelector = "off";
        };

        #--- MCP Servers (opencode turns GitHub's off for its local models; opencode.nix)
        context_servers = {
          nixos = {
            command = lib.getExe pkgs.mcp-nixos;
            args = [];
            env = {};
          };
          github = {
            command = "${githubMcp}";
            args = [];
            env = {};
          };
        };

        #--- Performance
        file_scan_exclusions = [
          "**/.git"
          "**/.direnv"
          "**/node_modules"
          "**/target"
          "**/.nix-profile"
          "**/result"
          "**/.cache"
        ];
      };
    in ''
      config_dir="$HOME/.config/zed"
      declarative_file="$config_dir/declarative-settings.json"
      settings_file="$config_dir/settings.json"
      new_file=${pkgs.writeText "zed-declarative-settings.json" zedDeclarativeSettings}

      if [[ -v DRY_RUN ]]; then
        echo "Would merge $new_file into $settings_file"
      else
        mkdir -p "$config_dir"
        # A missing or unreadable settings.json starts from the repo's settings
        if ! ${jq} -e . "$settings_file" > /dev/null 2>&1; then
          cp --no-preserve=mode "$new_file" "$settings_file"
        else
          # The last applied template is the merge's "old"; none on a first run
          ${jq} -e . "$declarative_file" > /dev/null 2>&1 \
            || echo '{}' > "$declarative_file"
          merged="$(${jq} --slurpfile old "$declarative_file" \
            --slurpfile new "$new_file" --argjson locked '${locked}' \
            -f ${../../../../lib/mutable-merge.jq} "$settings_file")"
          printf '%s\n' "$merged" > "$settings_file"
        fi
        # Also what Omni Settings' Zed reset puts back into settings.json
        cp --no-preserve=mode "$new_file" "$declarative_file"
      fi
    ''
  );
}
