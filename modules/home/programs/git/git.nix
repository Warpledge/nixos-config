#=====================================================================#
# GIT CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  user,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Git & Delta Settings
  #--------------------------------------------------------------------#
  programs.git = {
    enable = true;

    settings = {
      #--- git.name and git.email from the user's settings.nix
      user =
        {
          name =
            if user.git.name != null
            then user.git.name
            else config.home.username;
        }
        // lib.optionalAttrs (user.git.email != null) {inherit (user.git) email;};
      init.defaultBranch = "main";
      pull.rebase = true;
      credential.helper = "gpg";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      # Conventional Commits guide shown in the editor; mirrors the commit skill
      commit.template = "${./git-commit-template}";
    };

    ignores = [
      ".cache/"
      ".DS_Store"
      ".idea/"
      "*.swp"
      "*.elc"
      "auto-save-list"
      ".direnv/"
      "node_modules"
      "result"
      "result-*"
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "dank"; # from the include below
      line-numbers = true;
      # side-by-side = true;
      navigate = true;
    };
  };

  #--- delta's colours, written by DMS's matugen (theme/matugen.nix)
  programs.git.includes = [{path = "${config.xdg.configHome}/git/dank-delta.gitconfig";}];

  # Also sets gh as git's credential helper for github.com
  programs.gh.enable = true;
  # home.packages = [pkgs.git-lfs];
}
