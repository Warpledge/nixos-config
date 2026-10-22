#=====================================================================#
# GRIDCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "gridcraft";
      version = "0.10.0";
      hash = "sha256-SJ8A0yk2HSG07F93+wQngu23LDMUT4Pt5Dqj245SE5s=";
      description = "Spreadsheet";
    })
  ];
}
