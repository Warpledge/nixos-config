"""Reads and edits settings.nix files: plain attribute sets of true/false,
null, strings, numbers and lists. Edits replace only the text of one value
or binding, so comments and layout survive."""

import json
import re
from dataclasses import dataclass, field

IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_'-]*")
NUMBER = re.compile(r"-?[0-9]+(\.[0-9]+)?")


class NixError(Exception):
    pass


@dataclass
class Token:
    kind: str  # ident, string, number, punct
    text: str
    start: int
    end: int
    value: object = None


@dataclass
class Comment:
    text: str
    start: int
    line: int


@dataclass
class Binding:
    path: list
    value: object
    start: int
    end: int  # just past the `;`


@dataclass
class AttrSet:
    bindings: list
    start: int  # the `{`
    end: int  # just past the `}`


@dataclass
class ListValue:
    items: list
    start: int
    end: int


@dataclass
class Scalar:
    value: object
    start: int
    end: int


@dataclass
class Document:
    text: str
    root: AttrSet
    comments: list = field(default_factory=list)

    def line_of(self, offset):
        return self.text.count("\n", 0, offset)


#--- Tokenizer
def tokenize(text):
    tokens, comments = [], []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c.isspace():
            i += 1
        elif c == "#":
            j = text.find("\n", i)
            j = n if j < 0 else j
            comments.append(Comment(text[i:j], i, text.count("\n", 0, i)))
            i = j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j < 0:
                raise NixError("unterminated /* comment")
            i = j + 2
        elif c == '"':
            j, out = i + 1, []
            while j < n and text[j] != '"':
                if text[j] == "\\" and j + 1 < n:
                    out.append({"n": "\n", "t": "\t", "r": "\r"}.get(text[j + 1], text[j + 1]))
                    j += 2
                elif text.startswith("${", j):
                    raise NixError("string interpolation is not supported here")
                else:
                    out.append(text[j])
                    j += 1
            if j >= n:
                raise NixError("unterminated string")
            tokens.append(Token("string", text[i : j + 1], i, j + 1, "".join(out)))
            i = j + 1
        elif c in "{}[]=;.":
            tokens.append(Token("punct", c, i, i + 1))
            i += 1
        elif m := NUMBER.match(text, i):
            raw = m.group(0)
            value = float(raw) if "." in raw else int(raw)
            tokens.append(Token("number", raw, i, m.end(), value))
            i = m.end()
        elif m := IDENT.match(text, i):
            tokens.append(Token("ident", m.group(0), i, m.end()))
            i = m.end()
        else:
            raise NixError(f"unexpected {c!r} at line {text.count(chr(10), 0, i) + 1}")
    return tokens, comments


#--- Parser
class Parser:
    def __init__(self, text):
        self.text = text
        self.tokens, self.comments = tokenize(text)
        self.pos = 0

    def peek(self):
        return self.tokens[self.pos] if self.pos < len(self.tokens) else None

    def take(self, text=None):
        tok = self.peek()
        if tok is None or (text is not None and tok.text != text):
            where = f"line {self.text.count(chr(10), 0, tok.start) + 1}" if tok else "the end"
            raise NixError(f"expected {text or 'a value'} at {where}")
        self.pos += 1
        return tok

    def value(self):
        tok = self.peek()
        if tok is None:
            raise NixError("unexpected end of file")
        if tok.text == "{":
            return self.attrset()
        if tok.text == "[":
            start = self.take("[").start
            items = []
            while self.peek() and self.peek().text != "]":
                items.append(self.value())
            return ListValue(items, start, self.take("]").end)
        self.pos += 1
        if tok.kind in ("string", "number"):
            return Scalar(tok.value, tok.start, tok.end)
        if tok.kind == "ident" and tok.text in ("true", "false", "null"):
            return Scalar({"true": True, "false": False, "null": None}[tok.text], tok.start, tok.end)
        raise NixError(f"unsupported value {tok.text!r}")

    def attrset(self):
        start = self.take("{").start
        bindings = []
        while self.peek() and self.peek().text != "}":
            first = self.peek()
            path = [self.key()]
            while self.peek() and self.peek().text == ".":
                self.take(".")
                path.append(self.key())
            self.take("=")
            value = self.value()
            end = self.take(";").end
            bindings.append(Binding(path, value, first.start, end))
        return AttrSet(bindings, start, self.take("}").end)

    def key(self):
        tok = self.take()
        if tok.kind == "ident":
            return tok.text
        if tok.kind == "string":
            return tok.value
        raise NixError(f"bad attribute name {tok.text!r}")


def parse(text):
    p = Parser(text)
    root = p.value()
    if not isinstance(root, AttrSet) or p.peek() is not None:
        raise NixError("a settings file must be one { ... } set")
    return Document(text, root, p.comments)


#--- Values
def to_python(node):
    if isinstance(node, Scalar):
        return node.value
    if isinstance(node, ListValue):
        return [to_python(i) for i in node.items]
    out = {}
    for b in node.bindings:
        cur = out
        for k in b.path[:-1]:
            cur = cur.setdefault(k, {})
        last = b.path[-1]
        value = to_python(b.value)
        if isinstance(cur.get(last), dict) and isinstance(value, dict):
            cur[last].update(value)
        else:
            cur[last] = value
    return out


def nix_value(value):
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False).replace("${", "\\${")
    if isinstance(value, list):
        return "[" + " ".join(nix_value(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{" + "".join(f"{nix_key(k)} = {nix_value(v)}; " for k, v in value.items()).rstrip() + "}"
    raise NixError(f"cannot write {value!r}")


def nix_key(key):
    return key if IDENT.fullmatch(key) and key not in ("true", "false", "null") else nix_value(key)


#--- Lookup
def find(attrset, path):
    """Returns (binding, None) when `path` is set, else (deepest set, rest)."""
    best = (attrset, path)
    for b in attrset.bindings:
        n = len(b.path)
        if b.path != path[:n]:
            continue
        if n == len(path):
            return b, None
        if isinstance(b.value, AttrSet):
            found, rest = find(b.value, path[n:])
            if rest is None:
                return found, None
            if len(rest) < len(best[1]):
                best = (found, rest)
    return best


#--- Edits
def set_value(text, path, value):
    doc = parse(text)
    found, rest = find(doc.root, path)
    new = nix_value(value)
    if rest is None:
        v = found.value
        return text[: v.start] + new + text[v.end :]
    binding = f"{'.'.join(nix_key(k) for k in rest)} = {new};"
    close = found.end - 1
    line_start = text.rfind("\n", 0, close) + 1
    if text[line_start:close].strip() == "":
        # Multi-line set: a new line above its closing brace
        indent = text[line_start:close] + "  "
        return text[:line_start] + indent + binding + "\n" + text[line_start:]
    before = text[:close].rstrip()
    sep = "" if before.endswith("{") else " "
    return before + sep + binding + text[close:]


def remove_value(text, path, keep=0):
    """Drops the binding for `path`, then any set it leaves empty, down to
    the first `keep` path elements."""
    doc = parse(text)
    found, rest = find(doc.root, path)
    if rest is not None:
        return text
    text = _cut(text, found.start, found.end)
    while len(path) - 1 > keep:
        path = path[:-1]
        doc = parse(text)
        found, rest = find(doc.root, path)
        if rest is not None or not isinstance(found.value, AttrSet):
            break
        inner = text[found.value.start + 1 : found.value.end - 1]
        if inner.strip():
            break
        text = _cut(text, found.start, found.end)
    return text


def _cut(text, start, end):
    line_start = text.rfind("\n", 0, start) + 1
    line_end = text.find("\n", end)
    line_end = len(text) if line_end < 0 else line_end
    after = text[end:line_end].strip()
    if text[line_start:start].strip() == "" and (after == "" or after.startswith("#")):
        return text[:line_start] + text[line_end + 1 :]
    return text[:start] + text[end:].lstrip(" ")
