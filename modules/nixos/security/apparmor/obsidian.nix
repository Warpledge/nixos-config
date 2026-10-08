#=====================================================================#
# APPARMOR: OBSIDIAN
#=====================================================================#
#- Community plugins run with full Node access, so the vault is the only
#- part of Documents it gets. Attaches to the launcher script, not the
#- shared electron binary other apps also run.
_: {
  security.apparmor.policies.obsidian = {
    state = "complain";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile obsidian /nix/store/*-obsidian-*/bin/obsidian {
        include <abstractions/nix-desktop-app>
        include <abstractions/nix-network>

        # Chromium's namespace sandbox
        userns,
        capability sys_admin,
        capability sys_chroot,
        capability setuid,
        capability setgid,
        capability sys_ptrace,
        @{PROC}/ r,
        owner @{PROC}/@{pid}/{uid_map,gid_map,setgroups} w,
        owner @{PROC}/@{pid}/oom_score_adj rw,
        owner /tmp/** m,

        /dev/tty rw,
        owner /run/user/[0-9]*/.obsidian-cli.sock rw,

        owner @{HOME}/Documents/obsidian-notes{,/**} rwlk,
        owner @{HOME}/.config/obsidian{,/**} rwk,
        owner @{HOME}/.pki/nssdb{,/**} rwk,

        # Attachments dragged in
        owner @{HOME}/{Downloads,Pictures}/** r,
      }
    '';
  };
}
