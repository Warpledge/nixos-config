#=====================================================================#
# WARPLEDGE'S HOME
#=====================================================================#
#- Overrides that apply on every machine this person logs in on.
{lib, ...}: {
  #--- llama-swap.nix makes the local model opencode's default; the Go plan's
  #--- DeepSeek should be what new sessions start on, and what titles them, so a
  #--- new session doesn't load the local model onto the GPU
  programs.opencode.settings.model =
    lib.mkForce "opencode-go/deepseek-v4.1-flash";
  programs.opencode.settings.small_model =
    lib.mkForce "opencode-go/deepseek-v4.1-flash";
}
