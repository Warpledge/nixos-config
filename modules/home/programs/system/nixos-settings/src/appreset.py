"""Reset buttons on the app switches: copy the settings the config last wrote
back over the app's own file, dropping what was changed in the app since. Only
apps whose config file stays writable are listed; the rest are store links a
rebuild already puts back."""

import os
import shutil
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

HOME = os.path.expanduser("~")
#--- user setting -> (app, its live file, the config's copy, pgrep -f pattern
#--- of a running app that rewrites the file on exit, extra warning)
APPS = {
    ("editors", "zed"): ("Zed", ".config/zed/settings.json",
                         ".config/zed/declarative-settings.json", None, ""),
    ("fileBrowsers", "duxFiles"): ("Dux Files", ".config/dfiles/ui-settings.json",
                                   ".local/state/dfiles-declared/ui-settings.json", None, ""),
    ("media", "freetube"): ("FreeTube", ".config/FreeTube/settings.db", ".config/FreeTube/hm_settings.db",
                            "freetube/resources/app.asar",
                            " Channels blocked in FreeTube but not yet synced to the config are "
                            "unblocked too."),
}


def button(window, setting):
    """A reset button for `setting`'s app, or None when it has none or isn't
    set up for this user."""
    entry = APPS.get(setting.path) if setting.domain == "user" else None
    if entry is None or not os.path.isfile(os.path.join(HOME, entry[2])):
        return None
    reset = Gtk.Button(icon_name="edit-clear-all-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                       tooltip_text=f"Reset {entry[0]}'s settings to the config's")
    reset.connect("clicked", lambda _: _confirm(window, *entry))
    return reset


def _confirm(window, app, live, declared, running, extra):
    dialog = Adw.AlertDialog(heading=f"Reset {app} settings?",
                             body=f"{app} goes back to the settings in the config. Everything changed in "
                                  f"{app}'s own settings since is lost; the old file is kept as "
                                  f"{os.path.basename(live)}.old." + extra)
    dialog.add_response("cancel", "Cancel")
    dialog.add_response("reset", "Reset")
    dialog.set_response_appearance("reset", Adw.ResponseAppearance.DESTRUCTIVE)
    dialog.set_default_response("cancel")
    dialog.set_close_response("cancel")

    def chosen(_, r):
        if r != "reset":
            return
        if running and subprocess.run(["pgrep", "-f", running], capture_output=True).returncode == 0:
            window.toast(f"Close {app} first; it rewrites its settings when it quits")
            return
        path = os.path.join(HOME, live)
        try:
            if os.path.isfile(path):
                shutil.copyfile(path, path + ".old")
            shutil.copyfile(os.path.join(HOME, declared), path)
        except OSError as e:
            window.toast(f"Couldn't reset {app}: {e.strerror}")
            return
        window.toast(f"{app} settings reset")
    dialog.connect("response", chosen)
    dialog.present(window)
