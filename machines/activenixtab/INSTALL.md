# Installing the Flow Z13

Run these on the Z13 after a fresh NixOS install, logged in as `kylerj`.

## 1. Clone the config

The checkout pulls from Warpledge's repo and pushes to the private `votex09/nixos-z13`, which holds Warpledge's main plus the Z13 commits on top.

```bash
cd ~
nix-shell -p git gh --run "gh auth login && gh repo clone votex09/nixos-z13 nixos-config"
cd nixos-config
git remote rename origin backup
git remote add upstream https://github.com/Warpledge/nixos-config.git
git fetch upstream
git branch -u upstream/main
git config branch.main.pushRemote backup
```

`git pull` then rebases the Z13 commits onto Warpledge's newest main, and `git push` saves them to the backup (`git push --force-with-lease` after a pull, since the rebase rewrites them).

## 2. Run setup

```bash
./setup.sh
```

Answer:

- **Set this computer up as:** Reinstall activenixtab
- **Use this install's stateVersion:** yes
- **Move the config to /etc/nixos-config:** no (`flakePath` keeps it in `~/nixos-config`)
- **Build now:** yes (the first build can take an hour or more)
- **Reboot now:** yes

## 3. After the reboot

Log in as `kylerj`. Try tap-Meta (launcher), Meta+T (terminal), rotating the screen and detaching the keyboard.

## 4. Keep the real hardware files

```bash
cd ~/nixos-config
git add machines/activenixtab
git commit -m "chore(activenixtab): real hardware config"
git push --force-with-lease
```
