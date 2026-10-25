---
name: onboard
description: Write the machines/<name>/CLAUDE.md and users/<name>/CLAUDE.md that tell Claude whose computer this is, its hardware and the person's own setup, for someone running this NixOS config on their own machine. Use when CLAUDE.md's "Who and which machine" check finds the current machine or user without a CLAUDE.md, when someone new says they installed this config, or when a person asks to update what Claude knows about their machine or setup.
---

# Onboard a machine or person

Each computer set up from this repo has `machines/<machine>/`, and each person
`users/<user>/`. Their `CLAUDE.md` files are the context Claude works from on that
computer, in place of the owner's (`eclipse`, `legion`, `warpledge`).

## 1. Identify

```bash
hostname; whoami
grep -l "hostName = \"$(hostname)\"" machines/*/settings.nix
```

The machine folder is the one whose `settings.nix` sets that `hostName`, else
`machines/<hostname>/`. The user folder is `users/<whoami>/`.

- No machine folder: the computer wasn't set up from this repo. Tell them to run
  `./setup.sh` themselves (it uses sudo and `nixos-rebuild`) and stop.
- No user folder, or the user isn't under `users` in the machine's `settings.nix`:
  tell them to run `./setup.sh add-user` and stop.
- Both `CLAUDE.md` files exist: this is an update. Read them and change only what the
  person asks for or what's now wrong.

## 2. Read what's already known

Read these together, skipping any that don't exist:

- `machines/<machine>/settings.nix`, `default.nix`, `hardware/gpu.nix`,
  `wm/niri.nix` and whatever else sits in the folder
- `users/<user>/settings.nix`

## 3. Detect the hardware

Run these (none need root) and keep the output to the lines that matter:

```bash
cat /sys/class/dmi/id/{sys_vendor,product_name,product_version} 2>/dev/null
lscpu | grep -E '^Model name|^CPU\(s\)'
lspci -nn | grep -Ei 'vga|3d|display'
free -h | head -2
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS | grep -v loop
ls /sys/class/power_supply 2>/dev/null        # a BAT* entry means a laptop
niri msg outputs 2>/dev/null | grep -E '^Output|Current mode'
```

## 4. Ask

Ask in one message, with what you detected filled in so they only correct it:

- Confirm the hardware summary, and which GPU should render on a hybrid laptop.
- What the computer is for (gaming, work, a server), and whether anyone else logs in.
- Anything that misbehaves or needs working around (suspend, a monitor, a device).
- For the user file: what they mainly use, and how they want Claude to work if it
  differs from the root `CLAUDE.md` (they can skip this).

The repo is public. Leave out serial numbers, IP and MAC addresses, Wi-Fi names,
locations and real names; offer Claude Code's local memory for anything private.

## 5. Write

Ask before adding sections beyond these (CLAUDE.md rule 9). Keep each file short:
facts Claude needs for this computer or person, each quirk pointing at the file that
handles it. Follow **Writing Style** in the root `CLAUDE.md`.

`machines/<machine>/CLAUDE.md`:

```markdown
# <machine>

<Whose computer and what it is: desktop or laptop, model, CPU, GPU, monitors.>

## Hardware

<GPU setup (which renders, any offload command), power management, what's off and why.>

## Where its config lives

- `default.nix` — <what it sets beyond the template>
- `<other file>` — <what it does>
```

`users/<user>/CLAUDE.md`:

```markdown
# <user>

<Which machines they log in on, admin or not, what they use the setup for.>

- <Apps or workflows Claude should know about>
- <How they want Claude to work, if it differs from the root CLAUDE.md>
```

## 6. Finish

`git add` both files and commit them through the `commit` skill
(`docs(<machine>): add the machine and user context for Claude`). Then tell the person
where their changes go (root `CLAUDE.md`, **Whose change is it**): one computer's in
`machines/<machine>/`, their own setup in `users/<user>/home.nix`, and features others
could use in `modules/`, which the `upstream` skill turns into a pull request.
