{
  pkgs,
  inputs,
  lib,
  config,
  user,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Dependencies
  #--------------------------------------------------------------------#
  home.packages = [
    #--- Nix Tooling
    inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
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

  #--- Zed settings: write the declarative template, merge with user settings
  home.activation.zedSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    let
      #--- Extract font names from Stylix config
      uiFontFamily = config.stylix.fonts.sansSerif.name;
      bufferFontFamily = config.stylix.fonts.monospace.name;
      terminalFontFamily = config.stylix.fonts.monospace.name;

      zedDeclarativeSettings = builtins.toJSON {
        #--- UI & Theme
        theme = "Catppuccin Mocha - No Italics";
        # The theme's Base (1e1e2e) swapped for Stylix's base00 (theme/stylix.nix)
        theme_overrides."Catppuccin Mocha - No Italics" = let
          base = config.lib.stylix.colors.withHashtag.base00;
        in {
          "toolbar.background" = base;
          "tab.active_background" = base;
          "editor.background" = base;
          "editor.gutter.background" = base;
          "terminal.background" = base;
          "terminal.ansi.background" = base;
        };
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
          show_diagnostics = "all";
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
        scrollbar = {
          show = "auto";
          git_diff = true;
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
        disable_ai = !user.llamaSwap.enable;
        agent =
          {
            button = true;
            dock = "right";
            favorite_models = [];
            model_parameters = [];
          }
          // lib.optionalAttrs user.llamaSwap.enable {
            default_model = {
              provider = "llama-swap";
              model = "lfm2.5-24b-a2b";
            };
          };
        #--- Local model served by ai/llama-swap.nix (same port and model id)
        language_models = lib.optionalAttrs user.llamaSwap.enable {
          openai_compatible.llama-swap = {
            api_url = "http://127.0.0.1:8090/v1";
            available_models = [
              {
                name = "lfm2.5-24b-a2b";
                display_name = "LFM2.5 24B A2B";
                max_tokens = 32768;
              }
            ];
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
          hyprlang = true;
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

        #--- MCP Servers
        context_servers = {
          nixos = {
            command = lib.getExe pkgs.mcp-nixos;
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
            set -e
            config_dir="$HOME/.config/zed"
            declarative_file="$config_dir/declarative-settings.json"
            settings_file="$config_dir/settings.json"

            # Ensure config directory exists
            mkdir -p "$config_dir"

            # Write the declarative settings template
            cat > "$declarative_file" <<'DECLARATIVE_EOF'
      ${zedDeclarativeSettings}
      DECLARATIVE_EOF

            # If settings.json doesn't exist, use declarative as the base
            if [ ! -f "$settings_file" ]; then
              ${pkgs.coreutils}/bin/cp "$declarative_file" "$settings_file"
              exit 0
            fi

            # Validate existing settings.json
            if ! ${pkgs.jq}/bin/jq -e . "$settings_file" > /dev/null 2>&1; then
              # If invalid JSON, replace with declarative version
              ${pkgs.coreutils}/bin/cp "$declarative_file" "$settings_file"
              exit 0
            fi

            # Declarative settings win: they're second in jq -s 'add'
            ${pkgs.jq}/bin/jq -s 'add' \
              "$settings_file" \
              "$declarative_file" \
              > "$settings_file.tmp"
            ${pkgs.coreutils}/bin/mv "$settings_file.tmp" "$settings_file"
    ''
  );
}
