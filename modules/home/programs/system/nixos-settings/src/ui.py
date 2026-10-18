"""Widgets and helpers the pages share."""

import re
import threading
import time

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Pango  # noqa: E402

try:  # GLib 2.86 moved it to GioUnix
    gi.require_version("GioUnix", "2.0")
    from gi.repository import GioUnix  # noqa: E402
    DesktopAppInfo = GioUnix.DesktopAppInfo
except (ValueError, ImportError):
    DesktopAppInfo = Gio.DesktopAppInfo

#--- descriptions.json marks app names **like this** and cautions !!like this!!
STRONG = re.compile(r"\*\*(.+?)\*\*")
CAUTION = re.compile(r"!!(.+?)!!")

#--- Only the theme's named colours, so Stylix's palette shows through
CSS = """
row label.title { font-weight: bold; }
row.nixm-plain image.expander-row-arrow { opacity: 0; }
.hero-icon { color: @accent_color; }
.hero-icon.success { color: @success_color; }
.hero-icon.error { color: @error_color; }
.hero-icon.warning { color: @warning_color; }
.chip { border-radius: 999px; padding: 1px 9px; font-size: 0.82em; font-weight: 700; }
.chip.accent { color: @accent_color; background-color: alpha(@accent_color, 0.15); }
.chip.warning { color: @warning_color; background-color: alpha(@warning_color, 0.15); }
.chip.error { color: @error_color; background-color: alpha(@error_color, 0.15); }
.chip.success { color: @success_color; background-color: alpha(@success_color, 0.15); }
.chip.neutral { background-color: alpha(currentColor, 0.1); }
.pending-dot { min-width: 8px; min-height: 8px; border-radius: 999px;
               background-color: @accent_color; }
.tile { padding: 12px 16px; }
.tile .value { font-size: 1.3em; font-weight: 800; }
.step-icon.done { color: @success_color; }
.step-icon.failed { color: @error_color; }
.step-icon.waiting { opacity: 0.35; }
.step-icon.skipped { opacity: 0.35; }
.log-view { font-size: 0.88em; }
.running-list { background: none; }
.big-progress { min-height: 10px; }
.big-progress trough, .big-progress progress { min-height: 10px; border-radius: 999px; }
.quick-link { padding: 12px 6px; min-width: 112px; }
.pop { animation: nsx-pop 500ms cubic-bezier(0.34, 1.56, 0.64, 1); }
@keyframes nsx-pop { from { opacity: 0; transform: scale(0.4); } to { opacity: 1; transform: scale(1); } }
.fade-in { animation: nsx-fade 300ms ease-out; }
@keyframes nsx-fade { from { opacity: 0; } to { opacity: 1; } }
"""


def load_css():
    provider = Gtk.CssProvider()
    provider.load_from_string(CSS)
    display = Gdk.Display.get_default()
    if display is not None:
        Gtk.StyleContext.add_provider_for_display(display, provider,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


#--------------------------------------------------------------------#
#-- Text
#--------------------------------------------------------------------#
def theme_colors():
    """The theme's named colours as hex, read off labels styled with them, for
    the places markup and text tags need a value rather than a CSS name."""
    colors = {}
    for name in ("accent", "warning", "error", "success"):
        c = Gtk.Label(css_classes=[name]).get_color()
        # Wide-gamut colours can come back outside 0..1; clamp to a valid sRGB hex
        to8 = [max(0, min(255, round(v * 255))) for v in (c.red, c.green, c.blue)]
        colors[name] = "#%02x%02x%02x" % tuple(to8)
    return colors


def valid_markup(text):
    try:
        Pango.parse_markup(text, -1, "\x01")
        return True
    except GLib.Error:
        return False


def plain(text):
    return STRONG.sub(r"\1", CAUTION.sub(r"\1", text))


def rich(text, colors):
    """Pango markup for description text, with its ** and !! marks coloured."""
    text = GLib.markup_escape_text(text)
    text = STRONG.sub(lambda m: f'<span weight="bold" foreground="{colors["accent"]}">{m.group(1)}</span>', text)
    return CAUTION.sub(lambda m: f'<span weight="bold" foreground="{colors["warning"]}">{m.group(1)}</span>',
                       text)


def esc(text):
    return GLib.markup_escape_text(str(text))


def label(text="", classes=(), markup=False, **props):
    props.setdefault("xalign", 0)
    props.setdefault("wrap", True)
    lbl = Gtk.Label(css_classes=list(classes), **props)
    if markup and valid_markup(text):
        lbl.set_markup(text)
    else:
        lbl.set_text(plain(text) if markup else text)
    return lbl


#--------------------------------------------------------------------#
#-- Icons
#--------------------------------------------------------------------#
def has_icon(name):
    display = Gdk.Display.get_default()
    return bool(name) and display is not None and Gtk.IconTheme.get_for_display(display).has_icon(name)


def first_icon(*names, fallback="applications-system-symbolic"):
    return next((n for n in names if has_icon(n)), fallback)


def app_image(candidates, size=32):
    """An image for the first of `candidates` that exists: an icon name, or a
    .desktop id whose own icon is used. None when none of them does."""
    for c in candidates or []:
        if c.endswith(".desktop"):
            try:
                info = DesktopAppInfo.new(c)
            except (TypeError, GLib.Error):
                info = None
            icon = info.get_icon() if info else None
            if icon is not None:
                return Gtk.Image(gicon=icon, pixel_size=size)
        elif has_icon(c):
            return Gtk.Image(icon_name=c, pixel_size=size)
    return None


#--------------------------------------------------------------------#
#-- Building blocks
#--------------------------------------------------------------------#
def chip(text, kind="neutral", tooltip=None):
    return Gtk.Label(label=text, css_classes=["chip", kind], valign=Gtk.Align.CENTER,
                     tooltip_text=tooltip)


def hero(icon, title, description="", size=64, symbolic=True, extra=None):
    """The centred icon, title and blurb at the top of a page."""
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin_bottom=6)
    if isinstance(icon, Gtk.Widget):
        image = icon
    else:
        image = Gtk.Image(icon_name=icon, pixel_size=size)
    if symbolic:
        image.add_css_class("hero-icon")
    box.append(image)
    box.append(Gtk.Label(label=title, css_classes=["title-1"], wrap=True,
                         justify=Gtk.Justification.CENTER))
    if description:
        box.append(Gtk.Label(label=description, css_classes=["dim-label"], wrap=True,
                             justify=Gtk.Justification.CENTER, max_width_chars=60))
    if extra is not None:
        box.append(extra)
    return box


def chips_box(chips):
    wrap = Adw.WrapBox(child_spacing=6, line_spacing=6, halign=Gtk.Align.CENTER, justify=0)
    for c in chips:
        wrap.append(c)
    return wrap


def link_icon():
    return first_icon("adw-external-link-symbolic", "external-link-symbolic", "go-next-symbolic")


def link_row(link, on_open):
    """A row that opens one of DankMaterialShell's settings tabs."""
    row = Adw.ActionRow(title=esc(link.title), subtitle=esc(link.subtitle), activatable=True,
                        tooltip_text="Opens DankMaterialShell's settings")
    row.add_prefix(Gtk.Image(icon_name=first_icon(link.icon), valign=Gtk.Align.CENTER))
    row.add_suffix(Gtk.Image(icon_name=link_icon(), valign=Gtk.Align.CENTER,
                             css_classes=["dim-label"]))
    row.connect("activated", lambda _: on_open(link))
    return row


def open_uri(window, uri):
    Gtk.UriLauncher.new(uri).launch(window, None, None, None)


#--------------------------------------------------------------------#
#-- Time
#--------------------------------------------------------------------#
def elapsed(seconds):
    seconds = int(max(0, seconds))
    h, rest = divmod(seconds, 3600)
    m, s = divmod(rest, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def ago(epoch):
    if not epoch:
        return "unknown"
    days = int((time.time() - epoch) // 86400)
    if days <= 0:
        return "today"
    if days == 1:
        return "yesterday"
    if days < 14:
        return f"{days} days ago"
    if days < 60:
        return f"{days // 7} weeks ago"
    return f"{days // 30} months ago"


def when(epoch):
    """"Today, 01:55", "Yesterday, 18:20" or "14 Oct, 09:12"."""
    t = time.localtime(epoch)
    today = time.localtime()
    clock = time.strftime("%H:%M", t)
    if t.tm_year == today.tm_year and t.tm_yday == today.tm_yday:
        return f"Today, {clock}"
    if t.tm_year == today.tm_year and t.tm_yday == today.tm_yday - 1:
        return f"Yesterday, {clock}"
    return time.strftime("%-d %b, %H:%M", t)


def day(epoch):
    return time.strftime("%-d %b %Y", time.localtime(epoch)) if epoch else "?"


#--------------------------------------------------------------------#
#-- Work off the main loop
#--------------------------------------------------------------------#
def run_async(work, done):
    """Runs `work` in a thread and hands done(result, error) back to the main loop."""
    def target():
        try:
            result, error = work(), None
        except Exception as e:  # noqa: BLE001
            result, error = None, e
        GLib.idle_add(lambda: done(result, error) and False)
    threading.Thread(target=target, daemon=True).start()
