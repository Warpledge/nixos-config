"""The People page: who can log in here, and for admins a form that adds a
person the way `./setup.sh add-user` does: users/<name>/settings.nix from the
template, their name in this machine's `users`, then a rebuild that makes the
account and sets its first password. It never replaces a file or folder: a
users/<name>/ that's already there is used as it is, and anything else in
the way stops it before a file is touched."""

import os
import pwd
import re
import shutil
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk  # noqa: E402

import backend  # noqa: E402
import nixfile  # noqa: E402
import ui  # noqa: E402

#--- setup.sh's valid_username, minus a leading _ (the _template folders)
LOGIN = re.compile(r"^[a-z][a-z0-9_-]{0,31}$")
RESERVED = {"root", "nobody", "greeter"}


class AddError(Exception):
    pass


def check(cfg, listed, name):
    """(problem or "", whether users/<name>/ is already set up)."""
    if not name:
        return "", False
    if not LOGIN.match(name):
        return "Use lowercase letters, digits, - and _, starting with a letter.", False
    if name in RESERVED:
        return f"{name} is reserved by the system.", False
    if name in listed:
        return f"{name} can already log in here.", False
    try:
        if pwd.getpwnam(name).pw_uid < 1000:
            return f"{name} is a system account.", False
    except KeyError:
        pass
    folder = os.path.join(cfg.flake, "users", name)
    if os.path.lexists(folder):
        if os.path.isdir(folder) and not os.path.islink(folder) \
                and os.path.isfile(os.path.join(folder, "settings.nix")):
            return "", True
        return f"users/{name} is already there but isn't a settings folder; sort it out by hand first.", False
    return "", False


def add(cfg, state, name, admin, git_name, git_email):
    """Writes the files and checks them. Returns undo() for a run that fails;
    on any error everything written is put back and AddError says why."""
    listed = list(state.resolved["users"])
    problem, existing = check(cfg, listed, name)
    if problem or not name:
        raise AddError(problem or "Type a login name.")
    folder = os.path.join(cfg.flake, "users", name)
    user_file = os.path.join(folder, "settings.nix")
    machine_file = cfg.file("machine")
    made_folder = made_file = staged = False
    old_machine = backend.slurp(machine_file)

    def undo():
        if staged:
            subprocess.run(["git", "-C", cfg.flake, "rm", "--cached", "-q", "--", user_file],
                           capture_output=True)
        if made_file and os.path.isfile(user_file):
            os.remove(user_file)
        if made_folder and os.path.isdir(folder) and not os.listdir(folder):
            os.rmdir(folder)
        if backend.slurp(machine_file) != old_machine:
            backend.save(machine_file, old_machine)
        return f"{name} was taken off again"

    try:
        changed = []
        if not existing:
            template = backend.slurp(os.path.join(cfg.flake, "users", "_template", "settings.nix"))
            text = template.replace("(TEMPLATE)", f"({name.upper()})", 1)
            if not admin:
                text = nixfile.set_value(text, ["admin"], False)
            if git_name:
                text = nixfile.set_value(text, ["git", "name"], git_name)
            if git_email:
                text = nixfile.set_value(text, ["git", "email"], git_email)
            try:
                os.mkdir(folder)  # fails rather than reuse a folder made since the check
                made_folder = True
                with open(user_file, "x") as f:  # "x": never replaces a file
                    made_file = True
                    f.write(text)
            except FileExistsError:
                raise AddError(f"users/{name} appeared while this ran; nothing was changed.")
            changed.append(user_file)

        #--- The machine's users, and mainUser once there are two or more
        text = nixfile.set_value(old_machine, ["users", name], {})
        doc = nixfile.to_python(nixfile.parse(old_machine).root)
        if "mainUser" not in doc or doc["mainUser"] is None:
            text = nixfile.set_value(text, ["mainUser"], state.resolved["mainUser"])
        backend.save(machine_file, text)
        changed.append(machine_file)
        if shutil.which("alejandra"):
            subprocess.run(["alejandra", "-q"] + changed, capture_output=True)

        #--- The flake only sees files git knows about
        if made_file:
            out = subprocess.run(["git", "-C", cfg.flake, "add", "--", user_file], capture_output=True,
                                 text=True)
            if out.returncode != 0:
                raise AddError(f"git couldn't stage users/{name}/settings.nix:\n{out.stderr.strip()}")
            staged = True
        backend.evaluate(cfg)
    except (AddError, backend.SettingsError, nixfile.NixError, OSError) as e:
        undo()
        if isinstance(e, AddError):
            raise
        raise AddError(f"Nothing was kept:\n{e}")
    return undo


class PeoplePage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        state = window.state
        self.listed = list(state.resolved["users"])
        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("system-users-symbolic", "avatar-default-symbolic"), "People",
                        "Who can log in to this computer. Each person picks their own apps by "
                        "opening Omni Settings on their own account."))
        self.add(top)

        group = Adw.PreferencesGroup(title="On This Computer")
        main = state.resolved.get("mainUser")
        for name in self.listed:
            user = state.resolved["users"][name]
            row = Adw.ActionRow(title=ui.esc(name), subtitle=ui.esc(f"users/{name}/settings.nix"))
            row.add_prefix(Gtk.Image(icon_name=ui.first_icon("avatar-default-symbolic"), valign=Gtk.Align.CENTER))
            tags = Gtk.Box(spacing=6, valign=Gtk.Align.CENTER)
            if name == window.cfg.user:
                tags.append(ui.chip("You", "accent"))
            if name == main and len(self.listed) > 1:
                tags.append(ui.chip("Owns the config", "neutral"))
            if user.get("admin"):
                tags.append(ui.chip("Admin", "neutral"))
            row.add_suffix(tags)
            group.add(row)
        self.add(group)

        form = Adw.PreferencesGroup(title="Add a Person",
                                    description="Makes their settings file from the template, lets them "
                                                "log in here, and rebuilds. They can change their apps "
                                                "afterwards from their own account.")
        self.name = Adw.EntryRow(title="Login name")
        self.name.connect("changed", lambda *_: self._validate())
        self.admin = Adw.SwitchRow(title="Admin", subtitle="Can use sudo, rebuild and change this "
                                                           "computer's settings")
        self.git_name = Adw.EntryRow(title="Name on git commits (optional)")
        self.git_email = Adw.EntryRow(title="Email on git commits (optional)")
        self.password = Adw.PasswordEntryRow(title="Password")
        self.again = Adw.PasswordEntryRow(title="Password again")
        for row in (self.password, self.again):
            row.connect("changed", lambda *_: self._validate())
        self.problem = Gtk.Label(xalign=0, wrap=True, css_classes=["caption"], margin_top=10, visible=False)
        self.add_button = Gtk.Button(label="Add and Rebuild", halign=Gtk.Align.END, margin_top=12,
                                     css_classes=["pill", "suggested-action"], sensitive=False)
        self.add_button.connect("clicked", lambda _: self._add())
        for row in (self.name, self.admin, self.git_name, self.git_email, self.password, self.again):
            form.add(row)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.append(self.problem)
        box.append(self.add_button)
        form.add(box)
        allowed = window.direct and window.can_apply
        form.set_sensitive(allowed)
        if not allowed:
            form.set_description("Only an admin can add people.")
        self.add(form)
        self.existing = False

    def _say(self, text, kind="error"):
        self.problem.set_visible(bool(text))
        self.problem.set_label(text)
        self.problem.set_css_classes(["caption", kind])

    def _validate(self):
        name = self.name.get_text().strip()
        problem, self.existing = check(self.window.cfg, self.listed, name)
        if problem:
            self.name.add_css_class("error")
        else:
            self.name.remove_css_class("error")
        for row in (self.admin, self.git_name, self.git_email):
            row.set_sensitive(not self.existing)
        password, again = self.password.get_text(), self.again.get_text()
        if not problem and password and again and password != again:
            problem = "The passwords don't match."
        if problem:
            self._say(problem)
        elif self.existing:
            self._say(f"users/{name}/ is already set up, from another computer. Adding them here uses "
                      "it as it is.", "dim-label")
        else:
            self._say("")
        self.add_button.set_sensitive(bool(name) and not problem and bool(password) and password == again)

    def _add(self):
        window = self.window
        if window.busy or window.changes:
            window.toast("Apply or discard your changes first")
            return
        name = self.name.get_text().strip()
        password = self.password.get_text()
        args = (name, self.admin.get_active(), self.git_name.get_text().strip(), self.git_email.get_text().strip())
        if self.existing:
            args = (name, False, "", "")
        view = window._start(f"Adding {name}", ["write", "auth", "build", "compare", "switch", "boot", "password"],
                             f"{name} can log in now", titles={"write": "Write their settings"})
        view.step("write", "running")

        def written(undo, err):
            if err is not None:
                view.fail_step("write", f"Couldn't add {name}", str(err))
                return
            view.step("write", "done")
            window.run_undo = undo
            view.set_undo(f"Take {name} Off Again", undo)

            def start():
                run = window._root(window.helper).request({"rebuild": True, "mode": "auto", "newUser": name})
                # The password goes on the helper's stdin, never in its arguments
                run.get_stdin_pipe().write_bytes(GLib.Bytes.new((password + "\n").encode()), None)
                return run
            view.run(start)
        ui.run_async(lambda: add(window.cfg, window.state, *args), written)
