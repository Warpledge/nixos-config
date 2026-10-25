#=====================================================================#
# SMB CLIENT (WINDOWS AND SAMBA SHARES)
#=====================================================================#
_: let
  rule = "-t raw -p udp --dport 137 -j CT --helper netbios-ns";
in {
  #--------------------------------------------------------------------#
  #-- NetBIOS Name Lookup
  #--------------------------------------------------------------------#
  # Replies to a broadcast name query look unrequested to the firewall, so
  # smb://<server> can't find the server by name; the conntrack helper
  # marks them as related to the query.
  networking.firewall.extraCommands = "iptables -A OUTPUT ${rule}";
  networking.firewall.extraStopCommands = "iptables -D OUTPUT ${rule} || true";
}
