"""The apps installed here, for the File Types page: each desktop entry's id
(a .desktop file name) and its name, from the system and user profiles and
Flatpak's exports."""

import os
import pwd


def dirs():
    """Where desktop entries live, most specific last."""
    user = os.environ.get("USER") or pwd.getpwuid(os.getuid()).pw_name
    out = []
    for data in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":"):
        if data:
            out.append(os.path.join(data, "applications"))
    out += [
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
        f"/etc/profiles/per-user/{user}/share/applications",
        os.path.expanduser("~/.nix-profile/share/applications"),
        os.path.expanduser("~/.local/share/applications"),
        "/run/current-system/sw/share/applications",
    ]
    return out


def name_of(path):
    """A .desktop file's name and whether it asks to be hidden, from its
    [Desktop Entry] group."""
    name, hidden, in_entry = None, False, False
    try:
        with open(path, errors="replace") as f:
            for line in f:
                line = line.strip()
                if line.startswith("["):
                    in_entry = line == "[Desktop Entry]"
                elif in_entry and "=" in line:
                    key, value = line.split("=", 1)
                    if key == "Name" and name is None:
                        name = value
                    elif key in ("NoDisplay", "Hidden") and value.strip().lower() == "true":
                        hidden = True
    except OSError:
        return None, True
    return name, hidden


def apps():
    """Every installed app as {"id", "name"}, sorted by name; the first of the
    directories above with an entry wins, as XDG_DATA_DIRS orders them."""
    seen, out = {}, {}
    for folder in dirs():
        try:
            names = sorted(os.listdir(folder))
        except OSError:
            continue
        for file in names:
            if not file.endswith(".desktop") or file in seen:
                continue
            seen[file] = True
            name, hidden = name_of(os.path.join(folder, file))
            if name and not hidden:
                out[file] = {"id": file, "name": name}
    return sorted(out.values(), key=lambda a: (a["name"].casefold(), a["id"]))
