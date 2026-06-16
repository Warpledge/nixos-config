#=====================================================================#
# NUSHELL CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#
  #--- Nushell is the primary shell for this configuration
  #--- Uses carapace for completion instead of p10k/starship
  #--- p10k and starship are configured in zsh.nix for legacy shell support
  #--- (zsh is still used by nixm.nix script and some other legacy tools)

  programs = {
    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    nushell = {
      enable = true;

      plugins = with pkgs.nushellPlugins; [
        query
        gstat
        polars
      ];

      extraConfig = let
        conf = builtins.toJSON {
          show_banner = false;
          edit_mode = "vi";
          buffer_editor = "nvim";

          completions = {
            algorithm = "substring";
            sort = "smart";
            case_sensitive = false;
            quick = true;
            partial = true;
            use_ls_colors = true;
          };

          shell_integration = {
            osc2 = true;
            osc7 = true;
            osc8 = true;
          };

          use_kitty_protocol = true;
          bracketed_paste = true;
          use_ansi_coloring = true;
          error_style = "fancy";

          display_errors = {
            exit_code = false;
            termination_signal = true;
          };

          table = {
            mode = "single";
            index_mode = "always";
            show_empty = true;
            padding.left = 1;
            padding.right = 1;
            trim = {
              methodology = "wrapping";
              wrapping_try_keep_words = true;
              truncating_suffix = "...";
            };
            header_on_separator = true;
            abbreviated_row_count = null;
            footer_inheritance = true;
          };

          ls.use_ls_colors = true;
          rm.always_trash = false;

          menus = [
            {
              name = "completion_menu";
              only_buffer_difference = false;
              marker = "? ";
              type = {
                layout = "ide";
                min_competion_width = 0;
                max_completion_width = 150;
                max_completion_height = 25;
                padding = 0;
                border = false;
                cursor_offset = 0;
                description_mode = "prefer_right";
                min_description_width = 0;
                max_description_width = 50;
                max_description_height = 10;
                description_offset = 1;
                correct_cursor_pos = true;
              };
              style = {
                text = "white";
                selected_text = "white_reverse";
                match_text = {attr = "u";};
                selected_match_text = {attr = "ur";};
                description_text = "yellow";
              };
            }
          ];

          cursor_shape = {
            vi_insert = "line";
            vi_normal = "block";
          };

          highlight_resolved_externals = true;
        };
        completions = let
          completion = name: ''
            source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
          '';
        in
          names:
            builtins.foldl'
            (prev: str: "${prev}\n${str}") ""
            (map completion names);
      in ''
        $env.config = ${conf};

        ${completions ["git" "nix" "man" "rg" "gh" "glow" "bat"]}

        def fcd [] {
          let dir = (fd --type d | fzf | str trim)
          if ($dir != "") {
            cd $dir
          }
        }

        def installed [] {
          nix-store --query --requisites /run/current-system/ | parse --regex '.*?-(.*)' | get capture0 | fzf
        }

        def installedall [] {
          nix-store --query --requisites /run/current-system/ | fzf | wl-copy
        }

        def --env fm [...args] {
        	let tmp = (mktemp -t "yazi-cwd.XXXXX")
        	yazi ...$args --cwd-file $tmp
        	let cwd = (open $tmp)
        	if $cwd != "" and $cwd != $env.PWD {
        		cd $cwd
        	}
        	rm -fp $tmp
        }

        #--- Git commit with message function
        def gcm [msg] {
          git commit -m $msg
        }

        #--- Git add and commit with message function
        def gcu [msg] {
          git add .
          git commit -m $msg
        }
      '';

      shellAliases = {
        #--- Nix
        cleanup = "sudo nix-collect-garbage --delete-older-than 1d";
        listgen = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
        nixremove = "nix-store --gc";
        bloat = "nix path-info -Sh /run/current-system";

        #--- General
        c = "clear";
        e = "exit";
        q = "exit";
        cleanram = "sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'";
        trimall = "sudo fstrim -va";
        temp = "cd /tmp/";

        #--- Editor & IDE
        vim = "nvim";
        vi = "nvim";
        v = "nvim";
        zed = "zeditor";
        cdnix = "zeditor ~/nixos-config; cd ~/nixos-config";
        nano = "micro";

        #--- File Management
        cat = "bat --number --color=always --paging=never --tabs=2 --wrap=never";
        ls = "eza -h --git --icons --color=auto --group-directories-first -s extension";
        l = "eza -lF --time-style=long-iso --icons";
        ll = "eza -h --git --icons --color=auto --group-directories-first -s extension";
        tree = "eza --tree --icons";
        sl = "ls";
        y = "yazi";
        grep = "rg";
        open = "xdg-open";

        #--- Git
        g = "lazygit";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gpl = "git pull";
        gs = "git status";
        gd = "git diff";
        gco = "git checkout";
        gcb = "git checkout -b";
        gbr = "git branch";
        add = "git add .";
        commit = "git commit";
        push = "git push";
        pull = "git pull";
        diff = "git diff --staged";
        gcld = "git clone --depth 1";
        gitgrep = "git ls-files | rg";

        #--- System
        us = "systemctl --user";
        rs = "sudo systemctl";

        #--- Fun
        fetch = "fastfetch";
        anime = "ani-cli";
        f = "figlet";
      };

      environmentVariables = {
        PROMPT_INDICATOR_VI_INSERT = "  ";
        PROMPT_INDICATOR_VI_NORMAL = "∙ ";
        PROMPT_COMMAND = "";
        PROMPT_COMMAND_RIGHT = "";
        NIXPKGS_ALLOW_UNFREE = "1";
        NIXPKGS_ALLOW_INSECURE = "1";
        SHELL = "${pkgs.nushell}/bin/nu";
        EDITOR = "nvim";
        VISUAL = "nvim";
        CARAPACE_BRIDGES = "carapace,zsh,fish,bash";
      };
      extraEnv = "$env.CARAPACE_BRIDGES = 'carapace,zsh,fish,bash'";
    };
  };
}
