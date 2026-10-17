# Try lsfg-vk frame generation

**Goal:** generate extra frames in games locked to 60 fps so they use more of the 280 Hz OLED.

Added 2026-10-15.

## What's already in the repo

Nothing yet. nixpkgs unstable has `lsfg-vk` 2.0.0, a Vulkan layer that hooks into Vulkan apps and adds frames with Lossless Scaling's frame generation, and `lsfg-vk-ui` 2.0.0, its Qt6 configuration GUI (nixos MCP search and lsfg-vk.dev, 2026-10-15). It's licensed CC BY-NC-ND 4.0, which nixpkgs counts as unfree; `allowUnfree` is already on.

## Steps left

1. Buy Lossless Scaling on Steam, install it, and switch it to its `lsfg-vk` beta branch. lsfg-vk's install page asks for both before installing the layer.
2. Add the two packages through the add-app workflow (a `gaming.*` toggle in the user template and `users/warpledge/settings.nix`, a module in `modules/home/programs/gaming/tools/`, a README row).
3. Rebuild, then check the install: `vkcube` should print `lsfg-vk` INFO lines, and `lsfg-vk-cli healthcheck` should report no missing files.
4. Create a profile in `lsfg-vk-ui`. Profiles are matched to games by executable, so no launch options are needed; `LSFGVK_PROFILE` forces a profile and `DISABLE_LSFGVK=1` switches the layer off for one run.
5. Try it on a 60 fps-locked game, comparing latency and artifacts against a run with `DISABLE_LSFGVK=1`.

## Useful info

- It hooks Vulkan only, which covers DXVK and VKD3D games under Proton plus native Vulkan games, not OpenGL ones.
- Whether it works inside gamescope (`nix-vn`, `nix-rpgm`) hasn't been checked.

## Sources

- Getting started: https://lsfg-vk.dev/docs/getting-started/
- Installing: https://lsfg-vk.dev/docs/installation/
- Environment variables: https://lsfg-vk.dev/docs/configuration/environment-variables/
