# Turn the spare drives into game storage

**Goal:** wipe the three unused drives in the desktop and put games on them, so the system drive stops filling up.

Added 2026-10-16.

## Why

On 2026-10-16 the root filesystem on the NVMe drive was 93% full: 805 GB used, 64 GB free. Steam's library in `~/.local/share/Steam` took 468 GB and `~/Games` 111 GB (Heroic 65 GB, visual novels 47 GB). Three more drives sit in the machine, none of them mounted:

| Device | Model (`lsblk`) | Size | Contents |
| --- | --- | --- | --- |
| sda | WDC WDS100T2B0A, SSD | 1 TB | ESP plus a LUKS partition labelled `root` |
| sdb | Samsung SSD 850 PRO, SSD | 256 GB | ESP plus a LUKS partition labelled `root` |
| sdc | WDC WD10EZEX, 7200 rpm HDD | 1 TB | empty GPT, no partitions |

The two LUKS partitions hold an old CachyOS install with Hyprland and a Linux setup used for testing. Neither is needed any more.

## What's already in the repo

- `hosts/desktop/hardware/hardware-configuration.nix` mounts only the NVMe drive (`/` on LUKS with ext4, and `/boot`). Nothing refers to sda, sdb or sdc.
- `services.fstrim.enable` in `modules/nixos/services/desktop.nix` trims mounted SSDs once a week. On a LUKS volume the trim only reaches the drive if its crypttab line allows `discard`.
- No NixOS option writes a stage-2 crypttab: the only crypttab option, `boot.initrd.luks.devices.<name>.crypttabExtraOpts`, applies to the initrd. A drive unlocked after boot goes through `environment.etc.crypttab.text`.

## Steps left

Device letters can change between boots, so check `lsblk -o NAME,SIZE,MODEL` right before each destructive command.

1. **Optional last look.** `sudo cryptsetup open --readonly /dev/sda2 old`, mount `/dev/mapper/old` read-only on an empty directory and copy out anything worth keeping. Unmount and `sudo cryptsetup close old` afterwards. Same for `/dev/sdb2`.
2. **Wipe sda and set it up.** `blkdiscard` drops every block on an SSD, partition table included.

   ```bash
   sudo blkdiscard /dev/sda
   printf 'label: gpt\ntype=linux\n' | sudo sfdisk /dev/sda
   sudo cryptsetup luksFormat /dev/sda1
   sudo cryptsetup open /dev/sda1 games
   sudo mkfs.ext4 -L games /dev/mapper/games
   ```

3. **Add a key file on the encrypted root**, so the drive unlocks at boot without a second prompt. The passphrase from `luksFormat` remains a fallback; the key file stays out of the repo (rule 4).

   ```bash
   sudo install -d -m 700 /root/cryptsetup-keys.d
   sudo dd if=/dev/urandom of=/root/cryptsetup-keys.d/games.key bs=64 count=1
   sudo chmod 400 /root/cryptsetup-keys.d/games.key
   sudo cryptsetup luksAddKey /dev/sda1 /root/cryptsetup-keys.d/games.key
   ```

4. **Declare it** in a new `hosts/desktop/hardware/storage.nix`, imported from `hosts/desktop/default.nix`. `<uuid>` is sda1's LUKS UUID from `lsblk -f`. With `nofail` a dead or missing drive doesn't hold up boot, and `discard` lets the weekly trim through.

   ```nix
   environment.etc.crypttab.text = ''
     games UUID=<uuid> /root/cryptsetup-keys.d/games.key luks,discard,nofail
   '';
   fileSystems."/mnt/games" = {
     device = "/dev/mapper/games";
     fsType = "ext4";
     options = ["nofail"];
   };
   ```

   Then `nixm rebuild`, and `sudo chown warpledge:users /mnt/games` once.
5. **Move games over.** In Steam, Settings → Storage → Add Drive with `/mnt/games`, then move games across from the same page. Point Heroic's default install path at a folder on `/mnt/games` and move installed games from each game's page. `~/Games/Visual Novels` is plain files and moves with `mv`. Start one game from each launcher afterwards.
6. **sdb and sdc (optional).** The HDD suits files that don't need fast loads: LM Studio's models (19 GB in `~/.lmstudio` on 2026-10-16), video, or games you rarely play. The 256 GB SSD can become a second game drive. Both take steps 2 to 4 with their own name and key file; skip `blkdiscard` on the HDD, which doesn't support discard, and clear it with `sudo wipefs -a /dev/sdc` instead.
7. Delete this file once games run from the new drive.

## Sources

- Drive inventory: `lsblk -d -o NAME,SIZE,MODEL,ROTA,TRAN,PTTYPE` and `lsblk -o NAME,PARTLABEL,LABEL,UUID`, 2026-10-16
- Space use: `df -h /` and `du -sh`, 2026-10-16
- Discard support: `lsblk -D`, 2026-10-16 (sda and sdb report a 512B granularity, sdc 0B)
- `nofail`, `discard` and the key file field: crypttab(5)
- `label: gpt` and the `linux` type alias: sfdisk(8)
- Crypttab options in NixOS: option search on 2026-10-16, which found only `boot.initrd.luks.devices.<name>.crypttabExtraOpts`
