#=====================================================================#
# HOST BLOCKLISTS AND FILTERING
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Custom Host Blocklists
  #--------------------------------------------------------------------#
  networking.extraHosts =
    #--- Shady hosts blocklist (blocks suspicious/malicious sites)
    #--- Commit hash locked for reproducibility
    builtins.readFile (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/shreyasminocha/shady-hosts/fc9cc4020e80b3f87024c96178cba0f766b95e7a/hosts";
      sha256 = "jbsEiIcOjoglqLeptHhwWhvL/p0PI3DVMdGCzSXFgNA=";
    })
    + #--- Crypto phishing scam blocklist
    builtins.readFile (pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/MetaMask/eth-phishing-detect/3be0b9594f0bc6e3e699ee30cb2e809618539597/src/hosts.txt";
      sha256 = "b3HvaLxnUJZOANUL/p+XPNvu9Aod9YLHYYtCZT5Lan0=";
    });

  #--------------------------------------------------------------------#
  #-- Steven Black Host Blocklist
  #--------------------------------------------------------------------#
  networking = {
    stevenblack = {
      enable = true; # Enable Steven Black host blocklist
      block = [
        "fakenews" # Block fake news sites
        "gambling" # Block gambling sites
      ];
    };
  };
}
