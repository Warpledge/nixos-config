#=====================================================================#
# GODOT MCP
#=====================================================================#
#- The godot-mcp server (github.com/triforge0/godot-mcp), which lets
#- opencode drive the Godot editor through the project's godot_mcp plugin.
#- It only works with that project open in the editor, so each Godot
#- project's opencode.json adds it (the godot skill has the entry).
{pkgs, ...}: let
  #--- Keep in step with the plugin copied into each project's addons/godot_mcp
  godot-mcp = pkgs.buildGoModule {
    pname = "godot-mcp";
    version = "1.0.0-unstable-2026-07-31";
    src = pkgs.fetchFromGitHub {
      owner = "triforge0";
      repo = "godot-mcp";
      rev = "d7424c27374592513df5319c806cdcc7fe7f2617";
      hash = "sha256-L+8Ini8ktasqrkQN1VLbEZ3sOzflZc9UOBQSTViMsiY=";
    };
    vendorHash = "sha256-Vb5zsRXYV5xBmtp/dqrdUg2o2RFA8Xgtk0xCZbbf4vw=";
    subPackages = ["cmd/godot-mcp"];
    meta.mainProgram = "godot-mcp";
  };
in {
  #--------------------------------------------------------------------#
  #-- Server
  #--------------------------------------------------------------------#
  home.packages = [godot-mcp];
}
