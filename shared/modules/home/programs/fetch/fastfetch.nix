#=====================================================================#
# FASTFETCH CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#

  home.packages = with pkgs; [fastfetch chafa];

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "kitty-direct",
        "source": "${./nixos-logo.png}",
        "width": 29,
        "padding": {
          "right": 2
        }
      },
      "display": {
        "separator": "",
        "size": {
          "binaryPrefix": "si",
          "ndigits": 0
        },
        "percent": {
          "type": 1
        },
        "key": {
          "width": 12
        }
      },
      "modules": [
        {
          "type": "title",
          "color": {
            "user": "35",
            "host": "36"
          }
        },
        {
          "type": "separator",
          "string": "▔"
        },
        {
          "type": "os",
          "key": "╭─ 󱄅  OS",
          "format": "{3}",
          "keyColor": "32"
        },
        {
          "type": "kernel",
          "key": "├─ 󰌽  KN",
          "format": "{1} {2}",
          "keyColor": "32"
        },
        {
          "type": "shell",
          "key": "├─ 󰆍  SH",
          "format": "{1} {4}",
          "keyColor": "32"
        },
        {
          "type": "wm",
          "key": "╰─ 󱂬  WM",
          "keyColor": "32"
        },
        // {
        //   "type": "packages",
        //   "key": "󰏖  PK",
        //   "keyColor": "32"
        // },
        "break",
        {
          "type": "cpu",
          "key": "╭─ 󰻠  CPU",
          "keyColor": "34",
          "freqNdigits": 1,
          "temperature": true
        },
        {
          "type": "gpu",
          "key": "├─ 󰾲  GPU",
          "format": "{2}",
          "keyColor": "34"
        },
        {
          "type": "memory",
          "key": "├─ 󰍛  RAM",
          "keyColor": "34"
        },
        {
          "type": "disk",
          "key": "╰─ 󰋊  DSK",
          "keyColor": "34"
        },
        "break"
      ]
    }
  '';
}
