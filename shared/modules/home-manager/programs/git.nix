#=====================================================================#
# GIT CONFIGURATION
#=====================================================================#
{
  pkgs,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Git & Delta Settings
  #--------------------------------------------------------------------#
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "${username}";
        email = "null";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      credential.helper = "gpg";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
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
      line-numbers = true;
      # side-by-side = true;
      navigate = true;
    };
  };

  home.packages = [pkgs.gh]; # pkgs.git-lfs
}
