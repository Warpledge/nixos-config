#=====================================================================#
# SSH SERVER (OPENSSH + FAIL2BAN)
#=====================================================================#
#- Key-only access for one user. Port 22 is opened in network/core.nix,
#- not here, so the firewall list stays in one place.
#-
#- Enabling this without a key in authorizedKeys below leaves no way in:
#- password and keyboard-interactive auth are both off.
{
  config,
  lib,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- OpenSSH
  #--------------------------------------------------------------------#
  services.openssh = {
    enable = true;
    openFirewall = false;

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
      AllowUsers = [username];

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

  #--- Public keys allowed to log in; a public key is not a secret, so it
  #--- belongs in the repo. Empty means nobody can connect.
  users.users.${username}.openssh.authorizedKeys.keys = [
  ];

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
      assertion = lib.length config.users.users.${username}.openssh.authorizedKeys.keys > 0;
      message = "ssh.enable is on but no key is listed in services/ssh.nix; you would be locked out.";
    }
  ];
}
