#=====================================================================#
# HELIX EDITOR CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Editor Configuration
  #--------------------------------------------------------------------#
  #--- Helix is a modern modal editor with vim-like keybinds
  #--- but with a more intuitive "selection -> action" model
  #---
  #--- Basic usage:
  #--- - Normal mode: navigate and select text
  #--- - Insert mode: press 'i' to enter, ESC to exit
  #--- - Selection: use motions (w=word, e=end of word, b=back)
  #--- - Actions: d=delete, c=change, y=yank (copy), p=paste
  #--- - Space bar: opens command palette
  #--- - ? : shows keybind help

  programs.helix = {
    enable = true;
    defaultEditor = false; # Zed is default

    #--- Editor Settings
    settings = {
      #--- Editor behavior
      editor = {
        line-number = "relative";
        cursorline = true;
        cursorcolumn = false;
        auto-save = false;
        idle-timeout = 250;
        completion-timeout = 250;
        preview-completion-insert = true;
        color-modes = true;

        #--- Cursor shape
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        #--- File picker
        file-picker = {
          hidden = false;
          git-ignore = true;
        };

        #--- Status line
        statusline = {
          left = ["mode" "spinner" "file-name" "file-modification-indicator"];
          center = [];
          right = ["diagnostics" "selections" "position" "file-encoding"];
        };

        #--- LSP
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        #--- Indentation (2 spaces for Nix)
        indent-guides = {
          render = true;
          character = "│";
          skip-levels = 1;
        };

        #--- Whitespace rendering
        whitespace = {
          render = {
            space = "none";
            tab = "all";
            newline = "none";
          };
          characters = {
            tab = "→";
            tabpad = " ";
          };
        };

        #--- Soft wrap
        soft-wrap = {
          enable = false;
        };
      };

      #--- Keybinds
      keys.normal = {
        space = {
          w = ":w"; # Quick save
          q = ":q"; # Quit
          f = ":format"; # Format document
          space = "file_picker"; # File picker (like Telescope in nvim)
          b = "buffer_picker"; # Buffer picker
          s = "symbol_picker"; # Symbol picker (LSP)
          d = "diagnostics_picker"; # Diagnostics
        };

        #--- Clear search highlight
        esc = ["collapse_selection" "keep_primary_selection"];
      };

      keys.insert = {
        #--- Quick escape
        j.k = "normal_mode";
      };
    };

    #--- Language-Specific Configuration
    languages = {
      #--- Language server configuration
      language-server = {
        nixd = {
          command = "nixd";
        };
        typescript-language-server = {
          command = "typescript-language-server";
          args = ["--stdio"];
        };
        rust-analyzer = {
          command = "rust-analyzer";
        };
      };

      #--- Language configurations
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "alejandra";
            args = ["--quiet"];
          };
          language-servers = ["nixd"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }
        {
          name = "javascript";
          auto-format = true;
          language-servers = ["typescript-language-server"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }
        {
          name = "typescript";
          auto-format = true;
          language-servers = ["typescript-language-server"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }
        {
          name = "rust";
          auto-format = true;
          language-servers = ["rust-analyzer"];
        }
      ];
    };
  };

  #--------------------------------------------------------------------#
  #-- Additional Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    # LSP servers (already installed from zed.nix, but listed for clarity)
    # nixd
    # typescript-language-server
    # rust-analyzer
    # lua-language-server

    # Additional tools for Helix
    ripgrep
    fd
  ];

  #--------------------------------------------------------------------#
  #-- Quick Start Guide
  #--------------------------------------------------------------------#
  #--- Run: hx <file>
  #---
  #--- Essential keybinds:
  #--- - i = insert mode (before cursor)
  #--- - a = insert mode (after cursor)
  #--- - ESC or jk = back to normal mode
  #--- - Space = command palette (shows all commands)
  #--- - ? = keybind help
  #---
  #--- Navigation (normal mode):
  #--- - h/j/k/l = left/down/up/right
  #--- - w = next word start
  #--- - e = next word end
  #--- - b = previous word
  #--- - gg = go to file start
  #--- - ge = go to file end
  #--- - / = search forward
  #---
  #--- Selection (extends as you move):
  #--- - v = toggle selection mode
  #--- - x = select line
  #--- - ; = collapse selection to cursor
  #---
  #--- Actions (on selections):
  #--- - d = delete selection
  #--- - c = change selection (delete + insert)
  #--- - y = yank (copy)
  #--- - p = paste after
  #--- - P = paste before
  #--- - u = undo
  #--- - U = redo
  #---
  #--- Custom keybinds:
  #--- - Space w = save
  #--- - Space q = quit
  #--- - Space f = format document
  #--- - Space Space = file picker
  #--- - Space b = buffer picker
  #--- - Space s = symbol picker (LSP)
  #--- - Space d = diagnostics
  #--------------------------------------------------------------------#
}
