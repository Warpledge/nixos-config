#=====================================================================#
# NIRI KEYBINDS
#=====================================================================#
{
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Niri Keybindings
  #--------------------------------------------------------------------#
  programs.niri.settings.binds = {
    #--- Media Player Controls
    "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
    "XF86AudioStop".action.spawn = ["playerctl" "pause"];
    "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
    "XF86AudioNext".action.spawn = ["playerctl" "next"];

    #--- Screenshot Controls
    "Mod+Shift+Print".action.screenshot-screen = {write-to-disk = true;};
    "Mod+Print".action.screenshot-window = {write-to-disk = true;};
    "Print".action.screenshot = {show-pointer = false;};
    "Mod+Return".action.spawn = ["kitty"];

    "Mod+Q".action.close-window = {};
    "Mod+S".action.switch-preset-column-width = {};
    "Mod+D".action.expand-column-to-available-width = {};
    "Mod+F".action.maximize-column = {};
    "Mod+Shift+F".action.fullscreen-window = {};
    "Mod+Space".action.toggle-window-floating = {};

    "Mod+Alt+1".action.set-column-width = "3333%";
    "Mod+Alt+2".action.set-column-width = "50%";
    "Mod+Alt+3".action.set-column-width = "66667%";

    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Plus".action.set-column-width = "+10%";
    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+Shift+Plus".action.set-window-height = "+10%";

    "Mod+WheelScrollUp".action.focus-column-left = {};
    "Mod+WheelScrollDown".action.focus-column-right = {};
    "Mod+Shift+WheelScrollUp".action.focus-workspace-up = {};
    "Mod+Shift+WheelScrollDown".action.focus-workspace-down = {};

    #--- Focus Window
    "Mod+Left".action.focus-column-left = {};
    "Mod+Right".action.focus-column-right = {};
    "Mod+Up".action.focus-workspace-up = {};
    "Mod+Down".action.focus-workspace-down = {};

    #--- Window Movement
    "Mod+Shift+Left".action.move-column-left = {};
    "Mod+Shift+Right".action.move-column-right = {};
    "Mod+Shift+Up".action.focus-workspace-up = {};
    "Mod+Shift+Down".action.focus-workspace-down = {};

    #--- Window Resize
    "Mod+Ctrl+Left".action.set-column-width = "-80";
    "Mod+Ctrl+Right".action.set-column-width = "+80";
    "Mod+Ctrl+Up".action.set-window-height = "-80";
    "Mod+Ctrl+Down".action.set-window-height = "+80";

    "Mod+Tab".action.toggle-overview = {};
    "Mod+C".action.center-column = {};
    "Mod+X".action.switch-preset-window-height = {};
    "Mod+Shift+Z".action.reset-window-height = {};

    #--- Workspace Navigation (Number Keys)
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    #--- Move Window to Workspace (Number Keys)
    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

    #--- Apps
    "Mod+Shift+S".action.spawn = ["steam"];
    "Mod+Shift+D".action.spawn = ["vesktop"];
    "Mod+Shift+H".action.spawn = ["heroic"];
    "Mod+Shift+G".action.spawn = ["lutris"];
    "Mod+Shift+Y".action.spawn = ["Grayjay"];
    "Mod+Z".action.spawn = ["zeditor"];
    "Mod+B".action.spawn = ["zen-beta"];
    "Mod+E".action.spawn = ["nautilus"];
    "Mod+Shift+M".action.spawn = ["spotify"];

    #--- Waydroid
    "Mod+Shift+W".action.spawn = ["waydroid" "session" "start"];     # Start Waydroid
    "Mod+Ctrl+W".action.spawn = ["waydroid" "session" "stop"];       # Stop Waydroid

    #--- Screen Recording
    "Mod+Home".action.spawn = ["sh" "-c" "mkdir -p ~/Videos && notify-send -i media-record 'Recording Started' 'Saving to ~/Videos' && gpu-screen-recorder -w screen -f 30 -k h264 -q medium -a $(pactl get-default-sink).monitor -o ~/Videos/clip-$(date +%Y%m%d-%H%M%S).mp4"];
    "Mod+End".action.spawn = ["sh" "-c" "pkill -INT -f gpu-screen-recorder && notify-send -i media-playback-stop 'Recording Stopped' 'Clip saved to ~/Videos'"];
  };
}
