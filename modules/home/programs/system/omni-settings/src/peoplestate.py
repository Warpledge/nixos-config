"""The Users page: checking a login name and adding a person
the way `./setup.sh add-user` does: users/<name>/settings.nix from the
template, their name in this machine's `users`, checked. The rebuild that
makes the account and sets its first password follows. It never replaces a
file or folder: a users/<name>/ that's already there is used as it is, and
anything else in the way stops it before a file is touched."""

import os
import pwd
import re
import shutil
import subprocess

import backend
import nixfile

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
