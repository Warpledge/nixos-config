#=====================================================================#
# CONFIG PULL REMINDER
#=====================================================================#
#- Says when the config checkout is behind the branch it pulls from
#- (Warpledge's main). Pulling stays manual.
{machine, ...}: {
  programs.zsh.initContent = ''
    _config_behind_check() {
      [[ $PWD == ${machine.flakePath} ]] || return
      git rev-parse -q --verify '@{u}' >/dev/null || return
      timeout 3 git fetch --quiet upstream 2>/dev/null
      local n=$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)
      (( n > 0 )) && print -P "%F{yellow}nixos-config is $n commit(s) behind Warpledge: run git pull%f"
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _config_behind_check
    # First check waits for the first prompt: p10k's instant prompt warns
    # about output during startup
    _config_behind_first() {
      add-zsh-hook -d precmd _config_behind_first
      _config_behind_check
    }
    add-zsh-hook precmd _config_behind_first
  '';

  # git pull replays the local commits on top of Warpledge's, setting
  # uncommitted changes aside and putting them back afterwards
  programs.git.settings.pull.rebase = true;
  programs.git.settings.rebase.autoStash = true;
}
