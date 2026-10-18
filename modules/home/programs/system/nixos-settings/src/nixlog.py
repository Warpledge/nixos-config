"""Turns a rebuild's output into progress the window can show. The stream mixes
nix's `--log-format internal-json` lines (`@nix {...}`), the helper's events
(`@ns {...}`) and plain text such as switch-to-configuration's output."""

import json
import re
import time
from collections import deque
from dataclasses import dataclass, field

#--- nix's ActivityType and ResultType values (src/libutil/logging.hh)
COPY_PATH, FILE_TRANSFER, REALISE, COPY_PATHS, BUILDS, BUILD = 100, 101, 102, 103, 104, 105
SUBSTITUTE, QUERY_PATH_INFO, FETCH_TREE = 108, 109, 112
BUILD_LOG_LINE, SET_PHASE, PROGRESS, SET_EXPECTED, POST_BUILD_LOG_LINE = 101, 104, 105, 106, 107
#--- msg levels: error, warn, notice, info, talkative
ERROR, WARN, NOTICE, INFO, TALKATIVE = 0, 1, 2, 3, 4

STORE_PATH = re.compile(r"/nix/store/[0-9a-z]{32}-([^/'\s]+)")
WILL_BUILD = re.compile(r"^th(?:is|ese) (?:(\d+) )?derivations? will be built")
WILL_FETCH = re.compile(r"^th(?:is|ese) (?:(\d+) )?paths? will be fetched(?: \(([\d.]+ \w+) download)?")
PHASE_NAME = re.compile(r"Phase$")
BUILDER_FAILED = re.compile(r"(?:builder for|Cannot build) '([^']+\.drv)'(?:.*?exit code (\d+))?", re.S)


def store_name(path):
    """`/nix/store/<hash>-firefox-131.0.drv` -> `firefox-131.0`."""
    m = STORE_PATH.search(path or "")
    if not m:
        return path or ""
    name = m.group(1)
    return name[:-4] if name.endswith(".drv") else name


def split(line):
    """(kind, payload): ("nix", dict), ("ns", dict) or ("text", str)."""
    for prefix, kind in (("@nix ", "nix"), ("@ns ", "ns")):
        if line.startswith(prefix):
            try:
                data = json.loads(line[len(prefix):])
            except ValueError:
                break
            if isinstance(data, dict):
                return kind, data
            break
    return "text", line


@dataclass
class Activity:
    id: int
    type: int
    text: str
    parent: int
    started: float
    name: str = ""
    phase: str = ""
    last_line: str = ""
    done: int = 0
    expected: int = 0
    lines: deque = field(default_factory=lambda: deque(maxlen=40))


class Progress:
    """Folds nix's JSON log into counts, running items and messages."""

    def __init__(self):
        self.acts = {}
        self.builds = [0, 0, 0, 0]  # done, expected, running, failed
        self.copies = [0, 0, 0, 0]
        self.transferred = {}  # file transfer id -> bytes so far, kept after it ends
        self.expected_bytes = {}  # realise activity id -> bytes it expects to download
        self.eval_files = 0
        self.evaluating = True
        self.will_build = 0
        self.will_fetch = 0
        self.fetch_size = ""
        self.errors = []
        self.warnings = []
        self.finished_logs = {}  # build name -> its last lines, for failures

    #--- Totals
    def downloaded(self):
        return sum(self.transferred.values())

    def download_total(self):
        return max(sum(self.expected_bytes.values()), self.downloaded())

    def fraction(self):
        """Share of builds and downloads done, or None while nothing's known."""
        expected = self.builds[1] + self.copies[1]
        if expected <= 0:
            return None
        return min(1.0, (self.builds[0] + self.copies[0]) / expected)

    def running(self):
        """Builds, downloads and fetches in flight, oldest first, as
        (kind, name, detail, started)."""
        out = []
        for a in sorted(self.acts.values(), key=lambda a: a.started):
            if a.type == BUILD:
                detail = a.last_line or (PHASE_NAME.sub("", a.phase) if a.phase else "")
                out.append(("build", a.name, detail, a.started))
            elif a.type == SUBSTITUTE:
                done, total = self._bytes_under(a.id)
                out.append(("download", a.name, (done, total), a.started))
            elif a.type == FETCH_TREE:
                out.append(("fetch", a.text, "", a.started))
        return out

    def _bytes_under(self, act_id):
        """Download progress of a substitution: its file transfer, two levels
        down (substitute -> copy path -> file transfer)."""
        for a in self.acts.values():
            if a.type != FILE_TRANSFER or not a.expected:
                continue
            parent = self.acts.get(a.parent)
            if a.parent == act_id or (parent is not None and parent.parent == act_id):
                return a.done, a.expected
        return 0, 0

    #--- Feeding
    def feed(self, data):
        """Takes one `@nix` object; returns log lines as (style, text), style
        being error, warning, info, dim or build (text: "name> line")."""
        action = data.get("action")
        if action == "msg":
            return self._msg(data)
        if action == "start":
            return self._start(data)
        if action == "stop":
            a = self.acts.pop(data.get("id"), None)
            if a is not None and a.type == BUILD:
                self.finished_logs[a.name] = list(a.lines)
                if len(self.finished_logs) > 30:
                    self.finished_logs.pop(next(iter(self.finished_logs)))
            return []
        if action == "result":
            return self._result(data)
        return []

    def _msg(self, data):
        level = data.get("level", INFO)
        text = data.get("msg", "")
        if level >= TALKATIVE:
            if text.startswith("evaluating file"):
                self.eval_files += 1
            return []
        plain = strip_ansi(text)
        if level <= ERROR:
            self.errors.append(plain)
            return [("error", plain)]
        if level == WARN:
            self.warnings.append(plain)
            return [("warning", plain)]
        m = WILL_BUILD.match(plain)
        if m:
            self.evaluating = False
            self.will_build = int(m.group(1) or 1)
        m = WILL_FETCH.match(plain)
        if m:
            self.evaluating = False
            self.will_fetch = int(m.group(1) or 1)
            self.fetch_size = m.group(2) or ""
        return [("info", plain)]

    def _start(self, data):
        kind = data.get("type", 0)
        fields = data.get("fields") or []
        a = Activity(data.get("id"), kind, data.get("text", ""), data.get("parent", 0), time.monotonic())
        if kind == BUILD:
            a.name = store_name(fields[0] if fields else a.text)
            self.evaluating = False
        elif kind == SUBSTITUTE:
            a.name = store_name(fields[0] if fields else a.text)
            self.evaluating = False
        elif kind in (REALISE, BUILDS, COPY_PATHS):
            self.evaluating = False
        elif kind == FILE_TRANSFER:
            a.name = str(fields[0]) if fields else ""  # the URL; only /nar/ ones count
        elif kind == FETCH_TREE:
            a.text = strip_ansi(a.text)
        self.acts[a.id] = a
        if kind == BUILD:
            return [("dim", f"Building {a.name}")]
        if kind == SUBSTITUTE:
            return [("dim", f"Downloading {a.name}")]
        if kind == FETCH_TREE and a.text:
            return [("dim", a.text)]
        return []

    def _result(self, data):
        kind = data.get("type")
        fields = data.get("fields") or []
        a = self.acts.get(data.get("id"))
        if kind in (BUILD_LOG_LINE, POST_BUILD_LOG_LINE) and fields:
            line = strip_ansi(str(fields[0])).rstrip()
            if a is not None:
                a.lines.append(line)
                if line.strip():
                    a.last_line = line.strip()
                return [("build", f"{a.name}> {line}")]
            return [("build", line)]
        if kind == SET_PHASE and fields and a is not None:
            a.phase = str(fields[0])
            return []
        if kind == PROGRESS and len(fields) >= 2:
            if a is None:
                return []
            a.done, a.expected = int(fields[0]), int(fields[1])
            if a.type == BUILDS:
                self.builds = [int(f) for f in (fields + [0, 0])[:4]]
            elif a.type == COPY_PATHS:
                self.copies = [int(f) for f in (fields + [0, 0])[:4]]
            elif a.type == FILE_TRANSFER and "/nar/" in a.name:
                self.transferred[a.id] = a.done
            return []
        if kind == SET_EXPECTED and len(fields) >= 2 and fields[0] == FILE_TRANSFER:
            self.expected_bytes[data.get("id")] = int(fields[1])
        return []


#--------------------------------------------------------------------#
#-- switch-to-configuration
#--------------------------------------------------------------------#
UNIT_LINES = {
    "stopping the following units: ": "stopped",
    "restarting the following units: ": "restarted",
    "reloading the following units: ": "reloaded",
    "starting the following units: ": "started",
    "the following new units were started: ": "started",
}
FAILED_UNITS = re.compile(r"^warning: the following units failed: (.+)$")


def strip_ansi(text):
    return re.sub(r"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07]*(\x07|\x1b\\)", "", text)


def unit_changes(lines):
    """Units the switch stopped, restarted, reloaded, started or saw fail."""
    out = {"stopped": [], "restarted": [], "reloaded": [], "started": [], "failed": []}
    for line in lines:
        line = strip_ansi(line).strip()
        for prefix, key in UNIT_LINES.items():
            if line.startswith(prefix):
                out[key] += [u.strip() for u in line[len(prefix):].split(",") if u.strip()]
        m = FAILED_UNITS.match(line)
        if m:
            out["failed"] += [u.strip() for u in m.group(1).split(",") if u.strip()]
    for key in out:
        out[key] = list(dict.fromkeys(out[key]))
    return out


def first_error(text):
    """The most useful line of a nix error: the last `error:` line, which names
    what went wrong rather than the trace leading to it."""
    lines = [l.rstrip() for l in strip_ansi(text).splitlines()]
    best = ""
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("error:"):
            rest = stripped[6:].strip()
            if rest:
                best = rest
            elif i + 1 < len(lines):
                best = lines[i + 1].strip()
    return best or (lines[0].strip() if lines else "")
