"""Read and write Minecraft's binary NBT, keeping every tag's type for a lossless rewrite.

Tags load as Tag(type, value): compounds hold a dict of Tags, lists a (element type,
[Tags]) pair, arrays a list of ints. `load`/`dump` take gzipped bytes, the format of
structure templates. `plain` turns a Tag into ordinary Python values for reading.
"""

import gzip
import io
import struct
from typing import NamedTuple

END, BYTE, SHORT, INT, LONG, FLOAT, DOUBLE, BYTES, STRING, LIST, COMPOUND, INTS, LONGS = (
    range(13)
)
SCALAR = {BYTE: ">b", SHORT: ">h", INT: ">i", LONG: ">q", FLOAT: ">f", DOUBLE: ">d"}
ARRAY = {BYTES: ">b", INTS: ">i", LONGS: ">q"}


class Tag(NamedTuple):
    type: int
    value: object


def _read(f, t):
    if t in SCALAR:
        fmt = SCALAR[t]
        return struct.unpack(fmt, f.read(struct.calcsize(fmt)))[0]
    if t in ARRAY:
        (n,) = struct.unpack(">i", f.read(4))
        fmt = ARRAY[t]
        return list(struct.unpack(f">{n}{fmt[1]}", f.read(n * struct.calcsize(fmt))))
    if t == STRING:
        (n,) = struct.unpack(">H", f.read(2))
        return f.read(n).decode("utf-8", "surrogatepass")
    if t == LIST:
        et = f.read(1)[0]
        (n,) = struct.unpack(">i", f.read(4))
        return (et, [Tag(et, _read(f, et)) for _ in range(n)])
    if t == COMPOUND:
        d = {}
        while (tt := f.read(1)[0]) != END:
            key = _read(f, STRING)  # before the value: the name comes first in the file
            d[key] = Tag(tt, _read(f, tt))
        return d
    raise ValueError(f"unknown NBT tag type {t}")


def _write(f, t, v):
    if t in SCALAR:
        f.write(struct.pack(SCALAR[t], v))
    elif t in ARRAY:
        f.write(struct.pack(">i", len(v)) + struct.pack(f">{len(v)}{ARRAY[t][1]}", *v))
    elif t == STRING:
        b = v.encode("utf-8", "surrogatepass")
        f.write(struct.pack(">H", len(b)) + b)
    elif t == LIST:
        et, items = v
        f.write(bytes([et]) + struct.pack(">i", len(items)))
        for item in items:
            _write(f, et, item.value)
    elif t == COMPOUND:
        for k, tag in v.items():
            f.write(bytes([tag.type]))
            _write(f, STRING, k)
            _write(f, tag.type, tag.value)
        f.write(bytes([END]))
    else:
        raise ValueError(f"unknown NBT tag type {t}")


def load(data):
    """(root name, root Tag) from gzipped NBT bytes."""
    f = io.BytesIO(gzip.decompress(data))
    t = f.read(1)[0]
    return _read(f, STRING), Tag(t, _read(f, t))


def dump(name, root):
    f = io.BytesIO()
    f.write(bytes([root.type]))
    _write(f, STRING, name)
    _write(f, root.type, root.value)
    return gzip.compress(f.getvalue(), mtime=0)


def plain(tag):
    if tag.type == COMPOUND:
        return {k: plain(v) for k, v in tag.value.items()}
    if tag.type == LIST:
        return [plain(v) for v in tag.value[1]]
    return tag.value


def string(s):
    return Tag(STRING, s)
