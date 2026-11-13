#=====================================================================#
# KDE PARTITIONMANAGER POLKIT & PACKAGE
#=====================================================================#
{pkgs, ...}: {
  # Install KDE Partition Manager
  environment.systemPackages = [pkgs.kdePackages.partitionmanager];

  # Wheel may authorize KDE Partition Manager actions without a password prompt
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id.startsWith("org.kde.partitionmanager")
          && subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
      }
    });
  '';
}
