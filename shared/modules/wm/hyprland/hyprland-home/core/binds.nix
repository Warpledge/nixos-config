#=====================================================================#
# HYPRLAND KEYBINDS
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Hyprland Keybinds
  #--------------------------------------------------------------------#
  wayland.windowManager.hyprland = {
    settings = {
      #--- Key Bindings
      bind = [
        #--- Special Workspace
        "SUPER, 0, togglespecialworkspace, scratchpad"
        "SUPER SHIFT, 0, movetoworkspace, special:scratchpad"

        #--- Applications
        "SUPER, Return, exec, kitty" # Terminal
        "SUPER, Z, exec, zeditor" # Code Editor
        "SUPER, B, exec, zen-beta" # Web Browser
        "SUPER, E, exec, nautilus" # Files

        #--- Waydroid
        "SUPER SHIFT, W, exec, waydroid session start && waydroid" # Start Waydroid
        "SUPER CTRL, W, exec, waydroid session stop" # Stop Waydroid

        #--- Gaming & XWayland Apps
        "SUPER SHIFT, S, exec, steam"
        "SUPER SHIFT, D, exec, vesktop" # Nixcord
        "SUPER SHIFT, H, exec, heroic" # Epic / GoG Launcher
        "SUPER SHIFT, G, exec, lutris" # Game Launcher
        "SUPER SHIFT, M, exec, spotify" # Spicetify

        #--- Window Management
        "SUPER, Q, killactive," # Close window
        "SUPER, Space, exec, toggle_float" # Toggle Floating
        "SUPER, F, fullscreen" # Toggle Fullscreen
        "SUPER, D, fullscreen, 1" # Toggle Maximize

        "SUPER, T, exec, toggle_opacity" # Toggle Opacity

        #--- Switch Workspace
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        #--- Move to Workspace
        "SUPER SHIFT, 1, movetoworkspacesilent, 1"
        "SUPER SHIFT, 2, movetoworkspacesilent, 2"
        "SUPER SHIFT, 3, movetoworkspacesilent, 3"
        "SUPER SHIFT, 4, movetoworkspacesilent, 4"
        "SUPER SHIFT, 5, movetoworkspacesilent, 5"
        "SUPER SHIFT, 6, movetoworkspacesilent, 6"
        "SUPER SHIFT, 7, movetoworkspacesilent, 7"
        "SUPER SHIFT, 8, movetoworkspacesilent, 8"
        "SUPER SHIFT, 9, movetoworkspacesilent, 9"

        #--- Focus Window
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        #--- Window Movement
        "SUPER SHIFT, left, movewindow, l"
        "SUPER SHIFT, right, movewindow, r"
        "SUPER SHIFT, up, movewindow, u"
        "SUPER SHIFT, down, movewindow, d"

        #--- Window Resize
        "SUPER CTRL, left, resizeactive, -80 0"
        "SUPER CTRL, right, resizeactive, 80 0"
        "SUPER CTRL, up, resizeactive, 0 -80"
        "SUPER CTRL, down, resizeactive, 0 80"
        "SUPER ALT, left, moveactive,  -80 0"
        "SUPER ALT, right, moveactive, 80 0"
        "SUPER ALT, up, moveactive, 0 -80"
        "SUPER ALT, down, moveactive, 0 80"

        #--- Media Controls
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop,exec, playerctl stop"

        #============= Screen Capture ================================
        ",Print, exec, slurp | grim -g - - | wl-copy"
        "SUPER, Print, exec, screenshot --save"
        "SUPER SHIFT, Print, exec, screenshot --swappy"

        #================= Extra =====================================
        #--- Workspaces
        "SUPER, mouse_up, workspace, e+1"
        "SUPER, mouse_down, workspace, e-1"
      ];

      bindm = [
        "SUPER,mouse:272, movewindow" # Move Window (mouse)
        "SUPER,mouse:273, resizewindow" # Resize Window (mouse)
      ];
    };
  };
}
