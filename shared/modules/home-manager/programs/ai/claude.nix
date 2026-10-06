#=====================================================================#
# CLAUDE CODE - ANTHROPIC AI CODING AGENT
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  config = lib.mkIf hostConfig.claude.enable {
    #--------------------------------------------------------------------#
    #-- Package Installation
    #--------------------------------------------------------------------#
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
    };
  };
}
