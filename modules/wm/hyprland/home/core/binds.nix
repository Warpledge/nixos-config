#=====================================================================#
# HYPRLAND KEYBINDS
#=====================================================================#
{lib, ...}: let
  lua = lib.generators.mkLuaInline;
  str = lib.generators.toLua {};
  bind = keys: dsp: {_args = [keys (lua dsp)];};
  exec = keys: cmd: bind keys "hl.dsp.exec_cmd(${str cmd})";
  workspaces = map toString (lib.range 1 9);
in {
  #--------------------------------------------------------------------#
  #-- Hyprland Keybinds
  #--------------------------------------------------------------------#
  wayland.windowManager.hyprland = {
    settings = {
      #--- Key Bindings
      bind =
        [
          #--- Special Workspace
          (bind "SUPER + 0" ''hl.dsp.workspace.toggle_special("scratchpad")'')
          (bind "SUPER + SHIFT + 0" ''hl.dsp.window.move({ workspace = "special:scratchpad" })'')

          #--- Applications
          (exec "SUPER + Return" "kitty") # Terminal
          (exec "SUPER + Z" "zeditor") # Code Editor
          (exec "SUPER + B" "zen-beta") # Web Browser
          (exec "SUPER + E" "nautilus") # Files

          #--- Gaming & XWayland Apps
          (exec "SUPER + SHIFT + S" "steam")
          (exec "SUPER + SHIFT + D" "vesktop") # Nixcord
          (exec "SUPER + SHIFT + H" "heroic") # Epic / GoG Launcher
          (exec "SUPER + SHIFT + G" "lutris") # Game Launcher
          (exec "SUPER + SHIFT + M" "spotify") # Spicetify
          (exec "SUPER + SHIFT + Y" "freetube")

          #--- Window Management
          (bind "SUPER + Q" "hl.dsp.window.close()") # Close window
          (exec "SUPER + Space" "toggle_float") # Toggle Floating
          (bind "SUPER + F" "hl.dsp.window.fullscreen()") # Toggle Fullscreen
          # Toggle Maximize
          (bind "SUPER + D" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')

          (exec "SUPER + T" "toggle_opacity") # Toggle Opacity
          (exec "SUPER + H" "toggle_hdr") # Toggle HDR on the main monitor
        ]
        #--- Switch Workspace
        ++ map (n: bind "SUPER + ${n}" "hl.dsp.focus({ workspace = ${n} })") workspaces
        #--- Move to Workspace
        ++ map (n: bind "SUPER + SHIFT + ${n}" "hl.dsp.window.move({ workspace = ${n}, follow = false })") workspaces
        ++ [
          #--- Focus Window
          (bind "SUPER + left" ''hl.dsp.focus({ direction = "left" })'')
          (bind "SUPER + right" ''hl.dsp.focus({ direction = "right" })'')
          (bind "SUPER + up" ''hl.dsp.focus({ direction = "up" })'')
          (bind "SUPER + down" ''hl.dsp.focus({ direction = "down" })'')

          #--- Window Movement
          (bind "SUPER + SHIFT + left" ''hl.dsp.window.move({ direction = "left" })'')
          (bind "SUPER + SHIFT + right" ''hl.dsp.window.move({ direction = "right" })'')
          (bind "SUPER + SHIFT + up" ''hl.dsp.window.move({ direction = "up" })'')
          (bind "SUPER + SHIFT + down" ''hl.dsp.window.move({ direction = "down" })'')

          #--- Window Resize
          (bind "SUPER + CTRL + left" "hl.dsp.window.resize({ x = -80, y = 0, relative = true })")
          (bind "SUPER + CTRL + right" "hl.dsp.window.resize({ x = 80, y = 0, relative = true })")
          (bind "SUPER + CTRL + up" "hl.dsp.window.resize({ x = 0, y = -80, relative = true })")
          (bind "SUPER + CTRL + down" "hl.dsp.window.resize({ x = 0, y = 80, relative = true })")
          (bind "SUPER + ALT + left" "hl.dsp.window.move({ x = -80, y = 0, relative = true })")
          (bind "SUPER + ALT + right" "hl.dsp.window.move({ x = 80, y = 0, relative = true })")
          (bind "SUPER + ALT + up" "hl.dsp.window.move({ x = 0, y = -80, relative = true })")
          (bind "SUPER + ALT + down" "hl.dsp.window.move({ x = 0, y = 80, relative = true })")

          #--- Media Controls
          (exec "XF86AudioPlay" "playerctl play-pause")
          (exec "XF86AudioNext" "playerctl next")
          (exec "XF86AudioPrev" "playerctl previous")
          (exec "XF86AudioStop" "playerctl stop")

          #--- Screenshot binds live with the other DMS commands in shell/dms/core.nix

          #================= Extra =====================================
          #--- Workspaces
          (bind "SUPER + mouse_up" ''hl.dsp.focus({ workspace = "e+1" })'')
          (bind "SUPER + mouse_down" ''hl.dsp.focus({ workspace = "e-1" })'')

          #--- Mouse (the drag/resize dispatchers make these mouse binds)
          (bind "SUPER + mouse:272" "hl.dsp.window.drag()") # Move Window (mouse)
          (bind "SUPER + mouse:273" "hl.dsp.window.resize()") # Resize Window (mouse)
        ];
    };
  };
}
