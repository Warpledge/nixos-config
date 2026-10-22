#=====================================================================#
# MATUGEN TEMPLATES (DMS)
#=====================================================================#
# DMS's matugen renders these on each theme change, beside its own built-in
# templates. An app module adds its entry and includes the output file.
{
  lib,
  machine,
  ...
}: {
  #--- Every user on the machine
  home-manager.users =
    lib.mapAttrs (_: _: {config, ...}: {
      options.matugen.templates = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            input = lib.mkOption {
              type = lib.types.path;
              description = "Template file, with matugen's {{colors.*}} variables.";
            };
            output = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path matugen writes; nothing else may own it.";
            };
          };
        });
        default = {};
        description = "Repo templates DMS's matugen renders, by name.";
      };

      config = {
        #--- Apps whose module includes the output; DMS's own niri template is off
        matugen.templates = let
          cfg = config.xdg.configHome;
          on = p: config.programs.${p}.enable;
          tpl = input: output: {inherit input output;};
        in
          {niri = tpl ./matugen/niri-colors.kdl "${cfg}/niri/dms/colors.kdl";}
          // lib.optionalAttrs (on "helix") {
            helix = tpl ./matugen/helix.toml "${cfg}/helix/themes/dank.toml";
          }
          // lib.optionalAttrs (on "micro") {
            micro = tpl ./matugen/micro.micro "${cfg}/micro/colorschemes/dank.micro";
          }
          // lib.optionalAttrs (on "atuin") {
            atuin = tpl ./matugen/atuin.toml "${cfg}/atuin/themes/dank.toml";
          }
          // lib.optionalAttrs (on "eza") {
            eza = tpl ./matugen/eza.yml "${cfg}/eza/theme.yml";
          }
          // lib.optionalAttrs (on "fzf") {
            fzf = tpl ./matugen/fzf.rc "${cfg}/fzf/dank.rc";
          }
          // lib.optionalAttrs (on "tmux") {
            tmux = tpl ./matugen/tmux.conf "${cfg}/tmux/dank.conf";
          }
          // lib.optionalAttrs (on "delta") {
            delta = tpl ./matugen/delta.gitconfig "${cfg}/git/dank-delta.gitconfig";
          }
          // lib.optionalAttrs config.programs.zsh.syntaxHighlighting.enable {
            zsh = tpl ./matugen/zsh-highlight.zsh "${cfg}/zsh/dank-highlight.zsh";
          }
          // lib.optionalAttrs (on "mpv") {
            mpv = tpl ./matugen/mpv.conf "${cfg}/mpv/dank.conf";
            uosc = tpl ./matugen/uosc.conf "${cfg}/mpv/script-opts/uosc.conf";
          }
          // lib.optionalAttrs (on "yazi") {
            yazi = tpl ./matugen/yazi.toml "${cfg}/yazi/theme.toml";
          }
          // lib.optionalAttrs (on "opencode") {
            opencode = tpl ./matugen/opencode.json "${cfg}/opencode/themes/dank.json";
          };

        #--- Before zsh-syntax-highlighting loads, where catppuccin/nix's port sat
        programs.zsh.initContent = lib.mkIf config.programs.zsh.syntaxHighlighting.enable (
          lib.mkOrder 950 ''
            [[ -r ${config.xdg.configHome}/zsh/dank-highlight.zsh ]] &&
              source ${config.xdg.configHome}/zsh/dank-highlight.zsh
          ''
        );

        # DMS appends every .toml in this folder to its matugen config
        xdg.configFile."matugen/dms/configs/repo.toml".text = lib.concatStrings (lib.mapAttrsToList (name: t: ''
            [templates.repo-${name}]
            input_path = '${t.input}'
            output_path = '${t.output}'

          '')
          config.matugen.templates);
      };
    })
    machine.users;
}
