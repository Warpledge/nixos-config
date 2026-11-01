"""Autocorrect and swipe for wvkbd. Reads the keys `wvkbd -o` prints on stdin and, on
space or punctuation, replaces a misspelled word when one correction clearly wins. It
only knows what was typed on the on-screen keyboard, never the app's text. Off until
SIGUSR1 (osk-autocorrect) turns it on; the state survives restarts. Swipe strokes
(wvkbd-swipe.patch) arrive as \\x02keys\\x03 and are typed as a word; SIGUSR2 (osk-swipe)
loads the dictionary ahead of the first one. Words stay in memory and are never logged,
except a correction you undo, kept in WORDS as yours: delete the file to forget them."""

import functools
import itertools
import math
import os
import select
import signal
import subprocess
import sys
import time

toggled = False


def on_toggle(*_):
    global toggled
    toggled = True


swipe_on = False


def on_swipe(*_):
    global swipe_on
    swipe_on = True


# Before the slower imports: these signals' default action would kill the keyboard
signal.signal(signal.SIGUSR1, on_toggle)
signal.signal(signal.SIGUSR2, on_swipe)

STATE_DIR = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
STATE = os.path.join(STATE_DIR, "osk-autocorrect-on")
SWIPE_STATE = os.path.join(STATE_DIR, "osk-swipe-on")  # osk-swipe keeps this one
WORDS = os.path.join(STATE_DIR, "osk-words")
PAUSE = 5.0  # seconds without a key after which a word's start can't be trusted
DELIMITERS = " .,!?;:"
# BUILT_IN in skip-menu.py matches; that menu edits SKIP_FILE
SKIP_APPS = ("kitty", "ghostty", "foot", "alacritty", "konsole", "keepassxc")
SKIP_FILE = os.path.join(
    os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "osk-autocorrect-skip"
)

# Letter rows and their left offsets in key widths; keep in sync with
# wvkbd-layout.patch
ROWS = (("qwertyuiop", 1.5), ("asdfghjkl", 1.75), ("zxcvbnm", 2.5))
KEY_POS = {c: (x + i, y) for y, (r, x) in enumerate(ROWS) for i, c in enumerate(r)}

# Edit costs: a touch typo is usually a near miss, so those cost least
NEAR_KEY = 0.45
FAR_KEY = 1.0
SWAP = 0.6
DOUBLED = 0.4
GAP = 1.0
FREQ_WEIGHT = 0.2  # score per factor of ten in how common a word is
MIN_MARGIN = 0.1  # how far the best candidate must beat the next one
MAX_COST = 1.65
COMMON = 200_000  # list count from which an unknown-to-Hunspell word counts as real
# Unknown tech words and names sit near rare words, so a weak match needs a common one
WEAK_COST = 1.0
WEAK_MIN_COUNT = 1_000_000
SHORT_LEN = 4
SHORT_MIN_COUNT = 100_000_000
# Left out: ones that are common words without the apostrophe (we're, let's, I'll, it's)
CONTRACTIONS = {
    c.replace("'", "").lower(): c
    for c in (
        "I'm I've don't can't won't didn't doesn't isn't wasn't aren't couldn't shouldn't"
        " wouldn't haven't that's what's there's you're they're you've you'll he's she's"
    ).split()
}
CONTRACTION_COUNT = 100_000_000  # how common they rank in swipe
STROKE_FREQ = 0.06  # swipe: score per factor of ten, against a stroke's shape match
STROKE_END_MISS = 0.3  # swipe: a word not starting or ending where the stroke did
PERSONAL_COUNT = 10_000_000  # how common your own words rank in swipe
PAIR_UNIT = 6_400_000  # the lowest count in the word pair list
PAIR_WEIGHT = 0.1  # autocorrect: score per factor of ten of PAIR_UNIT
STROKE_PAIR_WEIGHT = 0.15  # swipe: the same, against a stroke's shape match


def near(a, b):
    if a not in KEY_POS or b not in KEY_POS:
        return False
    (ax, ay), (bx, by) = KEY_POS[a], KEY_POS[b]
    return math.hypot(ax - bx, ay - by) < 1.3


def key_at(x, y):
    row = round(y)
    if not 0 <= row < len(ROWS):
        return None
    letters, offset = ROWS[row]
    i = math.floor(x - offset)
    return letters[i] if 0 <= i < len(letters) else None


@functools.lru_cache(maxsize=50_000)
def stroke_of(word):
    """The keys a straight stroke through a word's letters crosses."""
    keys = word[0]
    for a, b in zip(word, word[1:]):
        (ax, ay), (bx, by) = KEY_POS.get(a, (0, 0)), KEY_POS.get(b, (0, 0))
        for n in range(1, 21):
            k = key_at(ax + 0.5 + (bx - ax) * n / 20, ay + (by - ay) * n / 20)
            if k and k != keys[-1]:
                keys += k
    return keys


def plain_distance(a, b):
    row = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        previous, row[0] = row[0], i
        for j, cb in enumerate(b, 1):
            previous, row[j] = row[j], min(row[j] + 1, row[j - 1] + 1, previous + (ca != cb))
    return row[-1]


def typo_cost(typed, word):
    """Weighted edit distance from `word` to what was typed."""
    rows = [[0.0] * (len(word) + 1) for _ in range(len(typed) + 1)]
    for i in range(1, len(typed) + 1):
        rows[i][0] = i * GAP
    for j in range(1, len(word) + 1):
        rows[0][j] = j * GAP
    for i, t in enumerate(typed, 1):
        for j, w in enumerate(word, 1):
            sub = 0.0 if t == w else NEAR_KEY if near(t, w) else FAR_KEY
            extra = GAP
            # An extra letter that repeats or sits beside its neighbour is a slip
            if i > 1 and (t == typed[i - 2] or near(t, typed[i - 2])):
                extra = DOUBLED
            best = min(rows[i - 1][j - 1] + sub, rows[i - 1][j] + extra, rows[i][j - 1] + GAP)
            if i > 1 and j > 1 and t == word[j - 2] and typed[i - 2] == w:
                best = min(best, rows[i - 2][j - 2] + SWAP)
            rows[i][j] = best
    return rows[-1][-1]


class Speller:
    def __init__(self):
        # Slow to load, so only built once autocorrect is first on
        import importlib.resources

        from symspellpy import SymSpell

        self.sym = SymSpell(max_dictionary_edit_distance=2, prefix_length=7)
        book = importlib.resources.files("symspellpy") / "frequency_dictionary_en_82_765.txt"
        self.sym.load_dictionary(str(book), term_index=0, count_index=1)
        pairs = importlib.resources.files("symspellpy") / "frequency_bigramdictionary_en_243_342.txt"
        self.sym.load_bigram_dictionary(str(pairs), term_index=0, count_index=2)
        self.personal, self.personal_stamp = set(), None
        self.hunspell = subprocess.Popen(
            ["hunspell", "-a", "-d", "en_US"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        self.hunspell.stdout.readline()  # its banner

    def personal_words(self):
        """Your words, reread when the file changes or goes."""
        try:
            stamp = os.stat(WORDS).st_mtime_ns
        except OSError:
            stamp = None
        if stamp != self.personal_stamp:
            self.personal_stamp = stamp
            self.personal = set()
            if stamp is not None:
                with open(WORDS) as words:
                    self.personal = set(words.read().split())
        return self.personal

    def remember(self, word):
        self.personal_words().add(word)
        try:
            fd = os.open(WORDS, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
            with os.fdopen(fd, "a") as words:
                words.write(word + "\n")
        except OSError:
            pass  # still left alone until a restart

    def pair(self, previous, word):
        """How strongly a word follows the one before it, 0 for no evidence."""
        count = self.sym.bigrams.get(f"{previous} {word}", 0) if previous else 0
        return math.log10(1 + count / PAIR_UNIT)

    def known(self, word):
        if self.sym.words.get(word, 0) >= COMMON:
            return True
        self.hunspell.stdin.write(f"^{word}\n")
        answer = self.hunspell.stdout.readline()
        while self.hunspell.stdout.readline().strip():
            pass
        return answer[:1] in ("*", "+", "-")

    def decode_stroke(self, path, previous=None):
        """The word a swipe across these keys spells, or None. Its first and last
        letters must be on or beside the stroke's ends, the rest in order between."""
        best, best_score = None, None
        words = {
            **self.sym.words,
            **dict.fromkeys(CONTRACTIONS, CONTRACTION_COUNT),
            **dict.fromkeys(self.personal_words(), PERSONAL_COUNT),
        }
        for word, count in words.items():
            if len(word) < 2 or len(word) > len(path) + 3:
                continue
            if not (word[0] == path[0] or near(word[0], path[0])):
                continue
            if not (word[-1] == path[-1] or near(word[-1], path[-1])):
                continue
            # In order along the stroke, on or beside it: a finger falls short of keys.
            # A stroke crosses a doubled letter once
            middle = iter(path)
            if not all(
                any(k == c or near(k, c) for k in middle)
                for c, _ in itertools.groupby(word[1:-1])
            ):
                continue
            # How far the keys crossed are from the straight lines through the word
            shape = plain_distance(path, stroke_of(word)) / len(path)
            score = STROKE_FREQ * math.log10(count) - shape
            score -= STROKE_END_MISS * ((word[0] != path[0]) + (word[-1] != path[-1]))
            score += STROKE_PAIR_WEIGHT * self.pair(previous, word)
            if best_score is None or score > best_score:
                best, best_score = word, score
        return CONTRACTIONS.get(best, best)

    def correct(self, word, previous=None):
        """The correction for a lowercase word, or None to leave it alone."""
        from symspellpy import Verbosity

        if word in self.personal_words():
            return None
        if word in CONTRACTIONS:
            return CONTRACTIONS[word]
        # Two letters are too little to go on: "ok" would become "of"
        if len(word) < 3 or self.known(word):
            return None
        found = self.sym.lookup(word, Verbosity.ALL, max_edit_distance=2)
        scored = sorted(
            (
                typo_cost(word, s.term)
                - FREQ_WEIGHT * math.log10(s.count)
                - PAIR_WEIGHT * self.pair(previous, s.term),
                s.term,
            )
            for s in found
            if len(s.term) > 1 and self.known(s.term)
        )
        if not scored:
            return None
        score, best = scored[0]
        cost, count = typo_cost(word, best), self.sym.words[best]
        if cost > MAX_COST or (cost > WEAK_COST and count < WEAK_MIN_COUNT):
            return None
        if len(word) <= SHORT_LEN and count < SHORT_MIN_COUNT:
            return None
        if len(scored) > 1 and scored[1][0] - score < MIN_MARGIN:
            return None
        return best


def niri(what):
    import json

    out = subprocess.run(
        ["niri", "msg", "--json", what], capture_output=True, text=True, timeout=1
    )
    return json.loads(out.stdout)


def own_skip_list():
    """App ids to skip, one per line, read each time so edits apply at once."""
    try:
        with open(SKIP_FILE) as f:
            return tuple(line.strip().lower() for line in f if line.strip())
    except OSError:
        return ()


def safe_to_correct():
    """False in terminals and password managers, and over polkit or the lock screen."""
    try:
        app = (niri("focused-window") or {}).get("app_id") or ""
        grabbed = any(s["keyboard_interactivity"] == "Exclusive" for s in niri("layers"))
    except Exception:
        return False
    skipped = SKIP_APPS + own_skip_list()
    return bool(app) and not grabbed and not any(s in app.lower() for s in skipped)


class Typist:
    """Types through its own uinput keyboard."""

    SHIFTED = {"!": "1", "?": "/", ":": ";"}
    NAMES = {
        " ": "SPACE",
        ".": "DOT",
        ",": "COMMA",
        ";": "SEMICOLON",
        "/": "SLASH",
        "1": "1",
        "'": "APOSTROPHE",
    }

    def __init__(self):
        from evdev import UInput
        from evdev import ecodes as e

        self.e = e
        keys = [getattr(e, f"KEY_{c.upper()}") for c in "abcdefghijklmnopqrstuvwxyz"]
        keys += [getattr(e, f"KEY_{n}") for n in self.NAMES.values()]
        keys += [e.KEY_BACKSPACE, e.KEY_LEFTSHIFT]
        self.dev = UInput({e.EV_KEY: keys}, name="On-screen autocorrect")
        time.sleep(0.3)  # let the compositor pick the device up

    def tap(self, code, shift=False):
        e = self.e
        if shift:
            self.dev.write(e.EV_KEY, e.KEY_LEFTSHIFT, 1)
        self.dev.write(e.EV_KEY, code, 1)
        self.dev.syn()
        self.dev.write(e.EV_KEY, code, 0)
        if shift:
            self.dev.write(e.EV_KEY, e.KEY_LEFTSHIFT, 0)
        self.dev.syn()
        time.sleep(0.002)

    def erase(self, count):
        for _ in range(count):
            self.tap(self.e.KEY_BACKSPACE)

    def text(self, chars):
        for c in chars:
            base = self.SHIFTED.get(c, c)
            name = self.NAMES.get(base, base.upper())
            self.tap(getattr(self.e, f"KEY_{name}"), c.isupper() or c in self.SHIFTED)


class Corrector:
    def __init__(self, speller, typist, safe=safe_to_correct):
        self.speller = speller
        self.typist = typist
        self.safe = safe
        self.on = True
        self.word = ""
        self.clean = True  # the word's start is known to be the real start
        self.last_key = 0.0
        self.last_fix = None  # (what was typed, what replaced it)
        self.last_swiped = ""
        self.after_word = False  # text ends in a word: a stroke needs a space first
        self.pending = None  # an edit waiting for wvkbd to let go of its key
        self.stroke = None  # the keys of a stroke being read
        self.previous = None  # the word before this one, if it's the same sentence
        self.private = False  # a password or PIN field has focus
        self.before_swipe = None  # self.previous before the last stroke's word

    def replacement(self, typed):
        if not self.clean:
            return None
        if any(c.isupper() for c in typed[1:]):
            return None  # ALL CAPS, iPhone, McDonald
        fixed = self.speller.correct(typed.lower(), self.previous)
        if not fixed or not self.safe():
            return None
        return fixed.capitalize() if typed[0].isupper() else fixed

    def swiped(self, path):
        word = self.speller.decode_stroke(path.lower(), self.previous)
        self.word, self.clean, self.last_fix = "", True, None
        if word:
            self.before_swipe, self.previous = self.previous, word.lower()
            word = word.capitalize() if path[0].isupper() else word
            # The space goes before a word, so punctuation can follow it directly
            typed = (" " if self.after_word else "") + word
            self.typist.text(typed)
            self.last_swiped = typed
            self.after_word = True

    def key(self, ch, now):
        # A password or PIN field, when the app reports one: nothing is read or kept
        if ch in "\x05\x06":
            self.private = ch == "\x05"
            self.word, self.clean, self.previous = "", ch == "\x06", None
            self.last_fix, self.last_swiped, self.pending = None, "", None
            self.after_word = False
            return
        if self.private:
            return
        # wvkbd still holds a key until this marker, and the same key can't be pressed
        # twice, so anything that retypes or erases waits for it. A new key before the
        # marker means fast typing: its edit would land in the wrong place, so drop it.
        if ch == "\x04":
            pending, self.pending = self.pending, None
            if pending:
                pending()
            return
        self.pending = None
        if ch == "\x02":
            self.stroke = ""
            return
        if self.stroke is not None:
            if ch != "\x03":
                self.stroke += ch
                return
            path, self.stroke = self.stroke, None
            self.last_key = now
            if path:
                self.swiped(path)
            return
        swiped, self.last_swiped = self.last_swiped, ""
        if ch == "\b" and swiped:
            # wvkbd's backspace took the last letter; a word from a stroke goes whole
            self.pending = lambda: self.typist.erase(len(swiped) - 1)
            self.after_word = False
            self.previous = self.before_swipe
            self.last_key = now
            return
        if now - self.last_key > PAUSE:
            self.clean = not self.word
            self.word = ""
            self.last_fix = None
            self.previous = None
        self.last_key = now
        fix, self.last_fix = self.last_fix, None
        self.after_word = ch.isascii() and ch not in " \n\t\b\x1b"

        if ch == "\b":
            if fix and self.on:
                # wvkbd's backspace already took the delimiter
                typed, fixed = fix
                self.speller.remember(typed.lower())
                self.word = typed

                def undo():
                    self.typist.erase(len(fixed))
                    self.typist.text(typed)

                self.pending = undo
            elif self.word:
                self.word = self.word[:-1]
            else:
                self.clean = False
                self.previous = None
        elif ch.isascii() and ch.isalpha():
            self.word += ch
        elif ch in DELIMITERS:
            finished = self.word if self.clean else None
            if self.on and self.word:
                typed, fixed = self.word, self.replacement(self.word)
                if fixed:
                    finished = fixed

                    def replace():
                        self.typist.erase(len(typed) + 1)
                        self.typist.text(fixed + ch)
                        self.last_fix = (typed, fixed)

                    self.pending = replace
            if self.word:
                self.previous = finished.lower() if finished else None
            # Only a space keeps the sentence's thread; "," and "." break it
            if ch != " ":
                self.previous = None
            self.word, self.clean = "", True
        elif ch in "\n\t":
            self.word, self.clean, self.previous = "", True, None
        else:
            # An arrow, Fn key, digit or apostrophe: this isn't a plain word any more
            self.word, self.clean, self.previous = "", False, None


def main():
    global toggled, swipe_on
    corrector = None
    on = os.path.exists(STATE)

    def build():
        built = Corrector(Speller(), Typist())
        built.on = on
        return built

    if on or os.path.exists(SWIPE_STATE):
        corrector = build()
    decode = __import__("codecs").getincrementaldecoder("utf-8")(errors="replace")
    while True:
        if swipe_on:
            swipe_on = False
            if corrector is None:
                corrector = build()
        if toggled:
            toggled = False
            on = not on
            if on:
                open(STATE, "w").close()
            elif os.path.exists(STATE):
                os.remove(STATE)
            if on and corrector is None:
                corrector = build()
            if corrector:
                corrector.on = on
        if not select.select([0], [], [], 0.5)[0]:
            continue
        data = os.read(0, 4096)
        if not data:
            return
        if not corrector:
            continue
        for ch in decode.decode(data):
            try:
                corrector.key(ch, time.monotonic())
            except Exception as err:
                # Never the word itself: this reaches the journal
                print(f"autocorrect: {type(err).__name__}", file=sys.stderr)


if __name__ == "__main__":
    main()
