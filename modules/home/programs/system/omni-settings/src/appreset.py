"""Reset buttons on the app switches: put each setting the config declares
back to the value it last wrote, leaving every other setting in the app's file
as it is. Only apps whose config file stays writable are listed; the rest are
store links a rebuild already puts back. The resetting is in resetstate.py."""

import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

import resetstate  # noqa: E402


def button(window, setting):
    """A reset button for `setting`'s app, or None when it has none or isn't
    set up for this user."""
    entry = resetstate.available(setting.path) if setting.domain == "user" else None
    if entry is None:
        return None
    reset = Gtk.Button(icon_name="edit-clear-all-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                       tooltip_text=f"Reset {entry[0]}'s settings to the config's")
    reset.connect("clicked", lambda _: _confirm(window, setting.path, *entry))
    return reset


def _confirm(window, path, app, live, _declared, _running, extra):
    dialog = Adw.AlertDialog(heading=f"Reset {app} settings?",
                             body=f"Every setting the config sets for {app} goes back to the config's "
                                  f"value, losing what was changed in {app}; settings the config "
                                  f"leaves alone stay as they are. The old file is kept as "
                                  f"{os.path.basename(live)}.old." + extra)
    dialog.add_response("cancel", "Cancel")
    dialog.add_response("reset", "Reset")
    dialog.set_response_appearance("reset", Adw.ResponseAppearance.DESTRUCTIVE)
    dialog.set_default_response("cancel")
    dialog.set_close_response("cancel")

    def chosen(_, r):
        if r != "reset":
            return
        try:
            resetstate.reset(path)
        except ValueError as e:
            window.toast(str(e))
            return
        window.toast(f"{app} settings reset")
    dialog.connect("response", chosen)
    dialog.present(window)
