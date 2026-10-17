#=====================================================================#
# SSH SERVER (OPENSSH + FAIL2BAN)
#=====================================================================#
#- Key-only access for the machine's users. Port 22 opens with this module,
#- so only on machines with ssh.enable set in their settings.nix.
#-
#- Enabling this without a key in some user's ssh.authorizedKeys leaves no
#- way in: password and keyboard-interactive auth are both off.
{
  lib,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- OpenSSH
  #--------------------------------------------------------------------#
  services.openssh = {
    enable = true;
    openFirewall = true;

    #--- Host keys: ed25519 only, no RSA
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      #--- Authentication
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;
      AuthenticationMethods = "publickey";
      MaxAuthTries = 3;
      MaxSessions = 4;
      LoginGraceTime = "30s";
      AllowUsers = lib.attrNames machine.users;

      #--- Forwarding
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      GatewayPorts = "no";

      #--- fail2ban needs VERBOSE to see failed key attempts
      LogLevel = "VERBOSE";
      UseDns = false;
    };
  };

  #--- Public keys allowed to log in, from ssh.authorizedKeys in each user's
  #--- settings.nix. Empty means that user cannot connect.
  users.users = lib.mapAttrs (_: user: {openssh.authorizedKeys.keys = user.ssh.authorizedKeys;}) machine.users;

  #--------------------------------------------------------------------#
  #-- Fail2ban
  #--------------------------------------------------------------------#
  #- The sshd jail ships with the NixOS module and is enabled by default.
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "12h";
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "192.168.0.0/16" # LAN, so a fat-fingered local login cannot lock you out
    ];
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # 1 week
    };
  };

  #--------------------------------------------------------------------#
  #-- Assertion
  #--------------------------------------------------------------------#
  assertions = [
    {
      assertion = lib.any (user: user.ssh.authorizedKeys != []) (lib.attrValues machine.users);
      message = "ssh.enable is on but no user lists a key in ssh.authorizedKeys; you would be locked out.";
    }
  ];
}
