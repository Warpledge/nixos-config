# legion

warpledge's laptop, a Legion Slim 5: Ryzen 7 7735HS, hybrid AMD 680M and RTX 4070, a
1600p 165Hz panel. It doubles as the Minecraft server host.

## Hardware

TLP power management; conservation mode comes from `battery.chargeLimit` in `settings.nix`,
not TLP. The hybrid GPU defaults to the 680M; route an app to the RTX 4070
with `nvidia-offload <app>`. As the server host, sleep, suspend and hibernate are off, the
lid and power key are ignored, and DMS auto-lock is off under niri.

## Where its config lives

- `hardware/gpu.nix` and `wm/niri.nix` — PRIME offload and the WM's GPU variables
- `hardware/swapfile.nix`
- `hardware/storage.nix` — the second NVMe (SK Hynix) as LUKS storage on `/mnt/storage`,
  unlocked after boot from a key file on the encrypted root (crypttab)
- `minecraft-servers/` — GTNH and TerraFirmaGreg server definitions, plus `mcservers.nix`,
  an fzf picker over them. It's a **home-manager** module injected from `default.nix`
  through `home-manager.users.${machine.mainUser}.imports`, not a NixOS module, since the
  servers live in the main user's `~/Documents`. Their notes are in
  `docs/personal/gaming/minecraft_servers/`.

## Troubleshooting the GPU

`lspci | grep -i vga`, `env | grep -E 'DRI|VDPAU|LIBVA|VK'`. Verify offload with
`nvidia-offload glxinfo | grep "OpenGL renderer"`.
