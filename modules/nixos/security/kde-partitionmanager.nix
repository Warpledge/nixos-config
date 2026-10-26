#=====================================================================#
# KDE PARTITIONMANAGER POLKIT & PACKAGE
#=====================================================================#
{ pkgs, ... }: {
  # Install KDE Partition Manager
  environment.systemPackages = [ pkgs.kdePackages.partitionmanager ];

  # Allow members of the wheel group to authorize KDE Partition Manager actions without password prompts
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id.startsWith("org.kde.partitionmanager") && subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
      }
    });
  '';
}
