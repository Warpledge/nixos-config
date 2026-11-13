"""The window: search nixpkgs, install without a rebuild, keep an app for good,
and read what a failed rebuild blames in Ky's own files.

Every slow call runs off the main loop, so the window never freezes while nix
works."""

import sys
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk, Pango

import backend


class Window(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Apps", default_width=620, default_height=800)
        self.names_ready = False

        toolbar = Adw.ToolbarView()
        header = Adw.HeaderBar()
        self.spinner = Gtk.Spinner()
        header.pack_end(self.spinner)
        toolbar.add_top_bar(header)

        self.stack = Adw.ViewStack()
        switcher = Adw.ViewSwitcher(stack=self.stack, policy=Adw.ViewSwitcherPolicy.WIDE)
        header.set_title_widget(switcher)
        toolbar.set_content(self.stack)

        self.status = Gtk.Label(label="", xalign=0, ellipsize=Pango.EllipsizeMode.END)
        self.status.set_margin_start(12)
        self.status.set_margin_end(12)
        self.status.set_margin_top(6)
        self.status.set_margin_bottom(6)
        self.status.add_css_class("dim-label")
        toolbar.add_bottom_bar(self.status)
        self.set_content(toolbar)

        self.stack.add_titled(self.install_page(), "install", "Install")
        self.stack.add_titled(self.installed_page(), "installed", "Installed")
        self.stack.add_titled(self.repair_page(), "repair", "Repair")

        self.load_names()
        self.refresh_installed()

    #-- Pages -----------------------------------------------------------#
    def install_page(self):
        page = column()
        self.search = Gtk.SearchEntry(placeholder_text="Search nixpkgs")
        self.search.set_sensitive(False)
        self.search.connect("search-changed", self.on_search)
        page.append(self.search)

        self.results = listing()
        self.results.connect("row-activated", self.on_result_activated)
        page.append(scrolled(self.results))
        return page

    def installed_page(self):
        page = column()
        self.installed_list = listing()
        page.append(scrolled(self.installed_list))

        self.kept_label = Gtk.Label(label="Kept for good", xalign=0)
        self.kept_label.add_css_class("heading")
        self.kept_label.set_margin_top(6)
        page.append(self.kept_label)

        self.kept_list = listing()
        page.append(scrolled(self.kept_list))

        buttons = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.update_button = Gtk.Button(label="Update")
        self.update_button.set_tooltip_text(
            "Bring every app to the nixpkgs the system last rebuilt with."
        )
        self.update_button.connect("clicked", self.on_update_all)
        buttons.append(self.update_button)

        clean = Gtk.Button(label="Clean up duplicates")
        clean.set_tooltip_text(
            "Remove the extra copy of an app that is both installed and kept. The rebuild installs it."
        )
        clean.connect("clicked", self.on_tidy)
        buttons.append(clean)
        page.append(buttons)
        return page

    def repair_page(self):
        page = column()
        check = Gtk.Button(label="Check my config")
        check.add_css_class("suggested-action")
        check.set_halign(Gtk.Align.START)
        check.connect("clicked", self.on_check)
        page.append(check)

        self.report = Gtk.TextView(editable=False, monospace=True, wrap_mode=Gtk.WrapMode.WORD_CHAR)
        self.report.set_top_margin(8)
        self.report.set_bottom_margin(8)
        self.report.set_left_margin(8)
        self.report.set_right_margin(8)
        self.buffer = self.report.get_buffer()
        self.show_text("Checks your declarations, then evaluates the whole config.\n"
                       "Only lines naming your own files are listed.")
        page.append(scrolled(self.report, framed=True))
        return page

    #-- Helpers ---------------------------------------------------------#
    def busy(self, text):
        self.spinner.start()
        self.status.set_label(text)

    def idle(self, text=""):
        self.spinner.stop()
        self.status.set_label(text)

    def then(self, work, done, busy_text):
        """Run work() off the main loop, then done(ok, value) back on it."""
        self.busy(busy_text)

        def worker():
            try:
                result = (True, work())
            except Exception as error:  # a broken call reports, never closes the window
                result = (False, str(error))
            GLib.idle_add(self.finish, done, result)

        threading.Thread(target=worker, daemon=True).start()

    def finish(self, done, result):
        ok, value = result
        self.idle()
        done(ok, value)

    def show_text(self, text):
        self.buffer.set_text(text)

    def row(self, title, subtitle, actions):
        """One list row. actions is [(label, callback, suggested)], each
        callback given the button it was clicked from."""
        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        box.set_margin_top(10)
        box.set_margin_bottom(10)
        box.set_margin_start(12)
        box.set_margin_end(12)

        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text.set_hexpand(True)
        name = Gtk.Label(label=title, xalign=0, ellipsize=Pango.EllipsizeMode.END)
        text.append(name)
        if subtitle:
            sub = Gtk.Label(label=subtitle, xalign=0, ellipsize=Pango.EllipsizeMode.END)
            sub.add_css_class("dim-label")
            text.append(sub)
        box.append(text)

        for label, callback, suggested in actions:
            button = Gtk.Button(label=label)
            button.set_valign(Gtk.Align.CENTER)
            if suggested:
                button.add_css_class("suggested-action")
            button.connect("clicked", lambda _button, cb=callback: cb(_button))
            box.append(button)

        if not actions:
            row.set_activatable(False)
        row.set_child(box)
        return row

    #-- Install ---------------------------------------------------------#
    def load_names(self):
        def work():
            return len(backend.names())

        def done(ok, value):
            if ok:
                self.names_ready = True
                self.search.set_sensitive(True)
                self.idle(f"{value} packages in the index.")
            else:
                self.idle(f"The package index didn't load: {value}")

        self.then(work, done, "Reading the package index...")

    def on_search(self, entry):
        if not self.names_ready:
            return
        text = entry.get_text().strip()
        clear(self.results)
        if len(text) < 2:
            return
        for attr in backend.search(text):
            self.results.append(
                self.row(attr, "", [("Install", lambda btn, a=attr: self.on_install(a, btn), True)])
            )

    def on_result_activated(self, _list, row):
        """Details on tap, since a package name rarely says what it is."""
        name = row_name(row)
        if not name:
            return

        def work():
            return backend.preview(name)

        def done(ok, value):
            dialog = Adw.Dialog()
            dialog.set_title(name)
            dialog.set_content_width(560)
            dialog.set_content_height(420)
            body = Gtk.Label(label=value, xalign=0, yalign=0, wrap=True, selectable=True)
            body.set_margin_top(12)
            body.set_margin_bottom(12)
            body.set_margin_start(12)
            body.set_margin_end(12)
            dialog.set_child(scrolled(body, framed=False))
            dialog.present(self)

        self.then(work, done, f"Reading {name}...")

    def on_install(self, attr, button):
        button.set_sensitive(False)
        button.set_label("Working...")

        def work():
            return backend.install(attr)

        def done(called, value):
            ok = self.acted(called, value)
            button.set_sensitive(True)
            button.set_label("Installed" if ok else "Install")
            if ok:
                self.refresh_installed()

        self.then(work, done, f"Installing {attr}...")

    def on_remove(self, key, button):
        button.set_sensitive(False)

        def work():
            return backend.uninstall(key)

        def done(called, value):
            self.acted(called, value)
            self.refresh_installed()

        self.then(work, done, f"Removing {key}...")

    def on_update(self, key, info, button):
        button.set_sensitive(False)

        def work():
            return backend.update(key, info)

        def done(called, value):
            self.acted(called, value)
            self.refresh_installed()

        self.then(work, done, f"Updating {info['attr']}...")

    def on_update_all(self, _button):
        self.update_button.set_sensitive(False)

        def work():
            return backend.update_all()

        def done(called, value):
            self.acted(called, value)
            self.refresh_installed()

        self.then(work, done, "Bringing every app to the system's nixpkgs...")

    #-- Installed and kept ----------------------------------------------#
    def acted(self, called, value):
        """Status line for an action: the backend's (ok, text), or an
        exception's text when the call itself failed."""
        ok, text = value if called else (False, str(value))
        self.idle(text)
        return ok

    def refresh_installed(self):
        def work():
            return backend.installed(), backend.declared()

        def done(called, value):
            if not called:
                self.idle(str(value))
                return
            installed, kept = value
            clear(self.installed_list)
            stale = 0
            for key, info in sorted(installed.items(), key=lambda item: item[1]["attr"]):
                actions = []
                if info["stale"]:
                    stale += 1
                    actions.append(
                        ("Update", lambda btn, k=key, i=info: self.on_update(k, i, btn), True)
                    )
                actions.append(
                    ("Keep", lambda btn, a=info["attr"]: self.on_keep(a, btn), not info["stale"])
                )
                actions.append(("Remove", lambda btn, k=key: self.on_remove(k, btn), False))
                if info["stale"]:
                    subtitle = "update available"
                elif info["rev"]:
                    subtitle = "installed without a rebuild"
                else:
                    subtitle = "installed from a store path"
                self.installed_list.append(self.row(info["attr"], subtitle, actions))
            self.update_button.set_sensitive(bool(stale))
            self.update_button.set_label(f"Update {stale}" if stale else "Update")
            if not installed:
                self.installed_list.append(self.row("Nothing installed on its own", "", []))

            clear(self.kept_list)
            for group, attrs in sorted(kept.items()):
                for attr in attrs:
                    self.kept_list.append(
                        self.row(attr, f"kept, under {group}", [
                            ("Stop keeping", lambda btn, a=attr: self.on_unkeep(a, btn), False),
                        ])
                    )
            if not kept:
                self.kept_list.append(self.row("Nothing kept yet", "", []))

        self.then(work, done, "")

    def on_keep(self, attr, button):
        button.set_sensitive(False)

        def work():
            return backend.keep(attr)

        def done(called, value):
            self.acted(called, value)
            self.refresh_installed()

        self.then(work, done, f"Keeping {attr}...")

    def on_unkeep(self, attr, button):
        button.set_sensitive(False)

        def work():
            return backend.unkeep(attr)

        def done(called, value):
            self.acted(called, value)
            self.refresh_installed()

        self.then(work, done, f"Dropping {attr}...")

    def on_tidy(self, _button):
        def work():
            return backend.tidy()

        def done(called, value):
            self.acted(called, value)
            self.refresh_installed()

        self.then(work, done, "Cleaning up...")

    #-- Repair ----------------------------------------------------------#
    def on_check(self, _button):
        def work():
            return backend.check()

        def done(ok, value):
            if ok:
                self.show_text("\n\n".join(value))
                self.idle("Check finished.")
            else:
                self.show_text(value)
                self.idle("The check didn't finish.")

        self.then(work, done, "Evaluating the config, which takes a moment...")


def column():
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
    box.set_margin_top(12)
    box.set_margin_bottom(12)
    box.set_margin_start(12)
    box.set_margin_end(12)
    return box


def listing():
    box = Gtk.ListBox()
    box.set_selection_mode(Gtk.SelectionMode.NONE)
    box.add_css_class("boxed-list")
    box.set_valign(Gtk.Align.START)
    return box


def scrolled(child, framed=False):
    window = Gtk.ScrolledWindow(vexpand=True)
    window.set_child(child)
    window.set_has_frame(framed)
    return window


def clear(box):
    child = box.get_first_child()
    while child is not None:
        following = child.get_next_sibling()
        box.remove(child)
        child = following


def row_name(row):
    """The first label of a row, which is the package name."""
    box = row.get_child()
    inner = box.get_first_child()
    label = inner.get_first_child()
    return label.get_text() if label else ""


class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id="io.github.kylerj.Apps", flags=0)

    def do_activate(self):
        window = self.get_active_window() or Window(self)
        window.present()


def self_test():
    """Checks the parts that don't need a window; prints what it found."""
    print("nixpkgs:", backend.nixpkgs_ref()[:70])
    print("repo:", backend.REPO)
    count = len(backend.names())
    print("index:", count, "packages")
    hits = backend.search("kdenlive")
    print("search kdenlive:", hits[:3])
    ok, text = backend.validate("kdenlive")
    print("validate kdenlive:", ok, text)
    ok, text = backend.validate("this-package-does-not-exist")
    print("validate missing:", ok, text[:90])
    installed = backend.installed()
    stale = [info["attr"] for info in installed.values() if info["stale"]]
    print("locked nixpkgs:", (backend.locked()[0] or "unknown")[:12])
    print("profile:", len(installed), "apps,", len(stale), "stale:", stale)
    print("declared:", backend.declared() or "none")

    import json
    original = backend.MANIFEST
    backend.MANIFEST = backend.Path("/tmp/opencode/packages-test.json")
    backend.MANIFEST.write_text("{}\n")
    print("keep:", backend.keep("ripgrep"))
    print("declared now:", backend.declared())
    print("unkeep:", backend.unkeep("ripgrep"))
    print("file after:", json.loads(backend.MANIFEST.read_text()))
    backend.MANIFEST = original


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        sys.exit(App().run(sys.argv[:1]))
