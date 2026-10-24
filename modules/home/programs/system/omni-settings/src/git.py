"""The Git page: where the config repo stands, read-only. It fetches when it
opens, so the commits to pull are current, then lists changed files, commits
to push and pull, open pull requests (GitHub's API, signed in through gh when
it is) and recent commits."""

import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk  # noqa: E402

import ui  # noqa: E402
from gitstate import (MAX_FILES, STATES, github_repo, iso_epoch, remote, snapshot,  # noqa: E402, F401
                      summary)

ICONS = ("vcs-branch-symbolic", "branch-symbolic", "folder-remote-symbolic")
#--- One fetch at a time from this window's threads
_lock = threading.Lock()


def locked_remote(flake, repo, force):
    with _lock:
        return remote(flake, repo, force)


class GitPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        self.flake = window.cfg.flake
        self.repo = github_repo(self.flake)
        self.run = 0  # ignores results from an earlier refresh
        self.rows = {}  # group -> the rows it holds now

        top = Adw.PreferencesGroup()
        extra = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.chips = ui.chips_box([])
        self.refresh_button = Gtk.Button(label="Refresh", halign=Gtk.Align.CENTER, css_classes=["pill"],
                                         tooltip_text="Fetch from the remote and read everything again")
        self.refresh_button.connect("clicked", lambda _: self.refresh())
        extra.append(self.chips)
        extra.append(self.refresh_button)
        where = f"{self.flake}, on github.com/{self.repo}" if self.repo else self.flake
        top.add(ui.hero(ui.first_icon(*ICONS), "Git", f"Where the config repo stands: {where}.", extra=extra))
        self.add(top)

        self.status = Adw.PreferencesGroup(title="Status")
        self.changed = Adw.PreferencesGroup(title="Changed Files",
                                            description="Changes not committed yet")
        self.outgoing = Adw.PreferencesGroup(title="To Push", description="Commits here the remote doesn't have")
        self.incoming = Adw.PreferencesGroup(title="To Pull", description="Commits on the remote not pulled yet")
        self.prs = Adw.PreferencesGroup(title="Open Pull Requests")
        self.recent = Adw.PreferencesGroup(title="Recent Commits")
        if self.repo:
            for group, path, tip in ((self.prs, "pulls", "Open the pull requests on GitHub"),
                                     (self.recent, "commits", "Open the commit history on GitHub")):
                button = Gtk.Button(icon_name=ui.link_icon(), css_classes=["flat"], valign=Gtk.Align.CENTER,
                                    tooltip_text=tip)
                button.connect("clicked", lambda _, p=path: ui.open_uri(window, f"https://github.com/{self.repo}/{p}"))
                group.set_header_suffix(button)
        for group in (self.status, self.changed, self.outgoing, self.incoming, self.prs, self.recent):
            self.add(group)
        self.refresh(force=False)

    #--------------------------------------------------------------------#
    #-- Loading
    #--------------------------------------------------------------------#
    def refresh(self, force=True, quiet=False):
        """Reads everything again; quiet keeps the rows up while it loads."""
        if not GLib.find_program_in_path("git"):
            self._fill(self.status, [self._note("git isn't installed")])
            for group in (self.changed, self.outgoing, self.incoming, self.prs, self.recent):
                group.set_visible(False)
            self.refresh_button.set_visible(False)
            return
        self.run += 1
        run = self.run
        self.refresh_button.set_sensitive(False)
        if not quiet:
            for group in (self.status, self.prs, self.recent):
                self._fill(group, [self._loading()])
        if not self.repo:
            self._fill(self.prs, [self._note("The origin remote isn't on GitHub")])
        ui.run_async(lambda: (locked_remote(self.flake, self.repo, force), snapshot(self.flake)),
                     lambda out, err: run == self.run and self._loaded(out, err))

    def _loaded(self, out, err):
        if err is not None:
            self._show(None, err, None)
            return
        (fetch_err, prs, pr_err, limited), snap = out
        self._show(snap, None, fetch_err)
        if self.repo:
            self._prs(prs, pr_err, limited)

    def _show(self, out, err, fetch_err):
        self.refresh_button.set_sensitive(True)
        child = self.chips.get_first_child()
        while child is not None:
            following = child.get_next_sibling()
            self.chips.remove(child)
            child = following
        if err is not None:
            self.chips.append(ui.chip("Couldn't read", "warning"))
            self._fill(self.status, [self._note("Couldn't read the repo", str(err))])
            self._fill(self.recent, [])
            return
        status, upstream, changed, outgoing, incoming, recent, fetched = out

        chips = []
        if changed:
            chips.append(ui.chip(f"{len(changed)} changed", "accent"))
        if outgoing:
            chips.append(ui.chip(f"{len(outgoing)} to push", "neutral"))
        if incoming:
            chips.append(ui.chip(f"{len(incoming)} to pull", "warning"))
        if not chips:
            chips.append(ui.chip("Up to date" if upstream else "Committed", "success"))
        for c in chips:
            self.chips.append(c)

        branch = Adw.ActionRow(title="Branch", subtitle=ui.esc(f"{status.branch} → {upstream}" if upstream
                                                               else f"{status.branch}, not tracking a remote"))
        branch.add_prefix(Gtk.Image(icon_name=ui.first_icon(*ICONS), valign=Gtk.Align.CENTER))
        fetch = Adw.ActionRow(title="Last Fetched", subtitle_lines=3)
        fetch.add_prefix(Gtk.Image(icon_name=ui.first_icon("emblem-synchronizing-symbolic", "view-refresh-symbolic"),
                                   valign=Gtk.Align.CENTER))
        seen = ui.when(fetched) if fetched else "Never"
        if fetch_err is not None:
            colour = self.window.colors.get("warning", "orange")
            fetch.set_subtitle(f'{ui.esc(seen)}\n<span foreground="{colour}">'
                               f"Couldn't fetch now: {ui.esc(str(fetch_err))}</span>")
        else:
            fetch.set_subtitle(ui.esc(seen))
        self._fill(self.status, [branch, fetch])

        rows = [self._file(line) for line in changed[:MAX_FILES]]
        if len(changed) > MAX_FILES:
            rows.append(self._note(f"And {len(changed) - MAX_FILES} more"))
        self._fill(self.changed, rows)
        self._fill(self.outgoing, [self._commit(c) for c in outgoing])
        self._fill(self.incoming, [self._commit(c) for c in incoming])
        self._fill(self.recent, [self._commit(c) for c in recent] or [self._note("No commits yet")])
        for group, items in ((self.changed, changed), (self.outgoing, outgoing), (self.incoming, incoming)):
            group.set_visible(bool(items))
        self.window.set_git_badges(changed=len(changed), ahead=len(outgoing), behind=len(incoming))

    def _prs(self, out, err, limited):
        if limited:
            self._fill(self.prs, [self._note("GitHub's limit for requests without signing in is used up",
                                             "Sign in with gh auth login, or try again within the hour.")])
        elif err is not None:
            self._fill(self.prs, [self._note("Couldn't reach GitHub", str(err))])
        else:
            self._fill(self.prs, [self._pr(pr) for pr in out] or [self._note("No open pull requests")])
            self.window.set_git_badges(prs=len(out))

    #--------------------------------------------------------------------#
    #-- Rows
    #--------------------------------------------------------------------#
    def _fill(self, group, rows):
        for row in self.rows.get(group, []):
            group.remove(row)
        for row in rows:
            group.add(row)
        self.rows[group] = rows
        group.set_visible(True)

    def _loading(self):
        row = Adw.ActionRow(title="Loading…")
        row.add_suffix(Adw.Spinner(valign=Gtk.Align.CENTER))
        return row

    def _note(self, title, subtitle=""):
        return Adw.ActionRow(title=ui.esc(title), subtitle=ui.esc(subtitle), subtitle_lines=4,
                             css_classes=["dim-label"] if not subtitle else [])

    def _link(self, row, url):
        row.set_activatable(True)
        row.add_suffix(Gtk.Image(icon_name=ui.link_icon(), valign=Gtk.Align.CENTER, css_classes=["dim-label"]))
        row.connect("activated", lambda _: ui.open_uri(self.window, url))

    def _file(self, line):
        xy, path = line[:2], line[3:]
        state = STATES.get(xy.strip()[:1], xy.strip())
        row = Adw.ActionRow(title=ui.esc(path))
        row.add_suffix(ui.chip(state, "warning" if state == "conflict" else "neutral"))
        return row

    def _commit(self, c):
        short, full, subject, author, stamp = c
        row = Adw.ActionRow(title=ui.esc(subject), title_lines=2,
                            subtitle=ui.esc(f"{short} · {author} · {ui.when(int(stamp))}"))
        if self.repo:
            self._link(row, f"https://github.com/{self.repo}/commit/{full}")
        return row

    def _pr(self, pr):
        updated = iso_epoch(pr.get("updated_at"))
        bits = [(pr.get("user") or {}).get("login", "?"), (pr.get("head") or {}).get("label", "")]
        if updated:
            bits.append(f"updated {ui.ago(updated)}")
        row = Adw.ActionRow(title=ui.esc(f"#{pr.get('number')} {pr.get('title', '')}"), title_lines=2,
                            subtitle=ui.esc(" · ".join(b for b in bits if b)))
        if pr.get("draft"):
            row.add_suffix(ui.chip("Draft", "neutral"))
        if pr.get("html_url"):
            self._link(row, pr["html_url"])
        return row
