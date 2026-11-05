"""Reading a server: console lines into events, and `forge tps` and `list` replies
into numbers. Over RCON 1.7.10 joins reply lines with no break between them, so
the patterns don't lean on line ends.

1.7.10:  [14:02:40] [Server thread/INFO]: <Name> hello
Forge:   [04Nov2026 14:02:40.123] [Server thread/INFO] [net.minecraft.server.MinecraftServer/]: <Name> hello

Dimension names: 1.7.10's `forge tps` gives only IDs, and the only names in the log
come from `Saving chunks` at shutdown. Both walk the same table, in the same order,
except that the shutdown list puts 0, -1 and 1 first, so a stop pairs them up."""

import re

LINE = re.compile(r"^\[(?P<time>[^\]]*)\] \[(?P<thread>[^\]/]*)/(?P<level>[A-Z]+)\](?: \[(?P<tag>[^\]]*)\])?: (?P<text>.*)$")
CHAT = re.compile(r"^<(?P<name>[A-Za-z0-9_]{1,16})> (?P<text>.*)$")
SAY = re.compile(r"^\[(?P<name>[A-Za-z0-9_]{1,16})\] (?P<text>.*)$")
JOIN = re.compile(r"^(?P<name>[A-Za-z0-9_]{1,16}) joined the game$")
LEAVE = re.compile(r"^(?P<name>[A-Za-z0-9_]{1,16}) left the game$")
DONE = re.compile(r"^Done \([\d.,]+s\)!")
CRASH = re.compile(r"crash report has been saved to: (?P<path>\S+)", re.IGNORECASE)
SAVING = re.compile(r"^Saving chunks for level '[^']*'/(?P<name>.+)$")
LAG = "Can't keep up!"
#--- 1.7.10: "Running 2208ms behind, skipping 44 tick(s)"
#--- Later versions: "Running 2208ms or 44 ticks behind"
LAG_DETAIL = re.compile(r"Running (?P<ms>\d+)ms (?:behind, skipping|or) (?P<ticks>\d+) tick")
STOPPING = re.compile(r"^Stopping (the )?server")

TPS = re.compile(
    r"(?:Dim\s+(?P<dim>\S+?)(?:\s+\([^)]*\))?|(?P<overall>Overall))\s*:\s*"
    r"Mean tick time:\s*(?P<ms>[\d.,]+)\s*ms\.\s*Mean TPS:\s*(?P<tps>\d+[.,]\d{1,3}|\d+)"
)
LIST = re.compile(r"There are (?P<online>\d+)(?:/| of a max of )(?P<max>\d+) players online:\s*(?P<names>.*)", re.DOTALL)
#--- Lines the stdin fallback's polling produces, hidden from the console view
POLL_LINE = re.compile(r"Mean tick time:|There are \d+(/| of a max of )\d+ players online")

VANILLA_DIMS = {"0": "Overworld", "-1": "Nether", "1": "The End"}


def number(text):
    return float(text.replace(",", "."))


def parse_line(raw):
    """A console line as {time, thread, level, text, kind, ...}: kind is chat, join,
    leave, done, lag, crash, saving, stopping or "" for the rest."""
    match = LINE.match(raw)
    if not match:
        return {"time": "", "level": "", "text": raw, "kind": ""}
    event = {"time": match["time"].split(" ")[-1].split(".")[0][-8:], "level": match["level"],
             "text": match["text"], "kind": ""}
    text = match["text"]
    #--- Chat comes from Minecraft's own logger, so a mod's `[Name] text` line isn't chat
    tag = match["tag"] or ""
    if match["level"] == "INFO" and (not tag or tag.startswith(("net.minecraft", "minecraft"))):
        if m := CHAT.match(text):
            event.update(kind="chat", name=m["name"], message=m["text"])
        elif m := SAY.match(text):
            event.update(kind="chat", name=m["name"], message=m["text"], say=True)
        elif m := JOIN.match(text):
            event.update(kind="join", name=m["name"])
        elif m := LEAVE.match(text):
            event.update(kind="leave", name=m["name"])
        elif DONE.match(text):
            event["kind"] = "done"
        elif m := SAVING.match(text):
            event.update(kind="saving", dim=m["name"])
        elif STOPPING.match(text):
            event["kind"] = "stopping"
    if LAG in text:
        event["kind"] = "lag"
        if m := LAG_DETAIL.search(text):
            event.update(behindMs=int(m["ms"]), ticks=int(m["ticks"]))
    elif m := CRASH.search(text):
        event.update(kind="crash", path=m["path"])
    return event


def parse_tps(reply):
    """{"overall": {ms, tps} or None, "dims": [{id, ms, tps}, ...]} in the reply's order."""
    overall, dims = None, []
    for m in TPS.finditer(reply):
        row = {"ms": number(m["ms"]), "tps": number(m["tps"])}
        if m["overall"]:
            overall = row
        else:
            dims.append({"id": m["dim"], **row})
    return {"overall": overall, "dims": dims}


def parse_list(reply):
    """{"online", "max", "names"}, or None for another reply."""
    m = LIST.search(reply)
    if not m:
        return None
    names = [n for n in re.split(r"[,\s]+", m["names"].strip()) if re.fullmatch(r"[A-Za-z0-9_]{1,16}", n)]
    return {"online": int(m["online"]), "max": int(m["max"]), "names": names}


def pair_dim_names(tps_order, saved_names):
    """{id: name} from the last `forge tps` order and the `Saving chunks` names, or {}
    when the lists don't line up (a world loaded in between)."""
    first = [d for d in ("0", "-1", "1") if d in tps_order]
    rest = [d for d in tps_order if d not in first]
    ordered = first + rest
    if len(ordered) != len(saved_names):
        return {}
    return dict(zip(ordered, saved_names, strict=True))


def dim_name(dim, names):
    return names.get(dim) or VANILLA_DIMS.get(dim) or (dim if ":" in dim else f"Dim {dim}")
