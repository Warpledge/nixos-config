{
  pkgs,
  inputs,
  lib,
  config,
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
    pkgs.typescript-language-server
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

  #--- Script to manage Zed settings: write declarative template and merge with user settings
  home.activation.zedSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    let
      #--- Extract font names from Stylix config
      uiFontFamily = config.stylix.fonts.sansSerif.name;
      bufferFontFamily = config.stylix.fonts.monospace.name;
      terminalFontFamily = config.stylix.fonts.monospace.name;

      zedDeclarativeSettings = builtins.toJSON {
        #--- UI & Theme
        theme = "Catppuccin Mocha - No Italics";
        icon_theme = "Catppuccin Mocha";
        base_keymap = "VSCode";
        vim_mode = false;

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

        project_panel = {
          auto_fold_dirs = false;
          dock = "left";
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
          show_nav_history_buttons = true;
          show_tab_bar_buttons = true;
        };

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
            command = "nix";
            args = ["run" "github:utensils/mcp-nixos" "--"];
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

            # Merge: declarative settings take precedence (add declarative second in jq -s 'add')
            ${pkgs.jq}/bin/jq -s 'add' \
              "$settings_file" \
              "$declarative_file" \
              > "$settings_file.tmp"
            ${pkgs.coreutils}/bin/mv "$settings_file.tmp" "$settings_file"
    ''
  );
}
