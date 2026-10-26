---
name: godot
description: Write, debug and review Godot 4 games in GDScript - scripts, scenes, signals, physics, UI - and check them with the installed engine. Use whenever the work is in a folder with a project.godot file, or the user mentions Godot, GDScript, a .gd/.tscn file, nodes or scenes, or asks to look at a screenshot of their game.
---

# Godot 4 (GDScript)

The installed engine is Godot 4.7 (`godot --version`). It is the standard build, so C#
scripts don't run; write GDScript.

## Start of a task

1. Read `project.godot`: `config/features` gives the Godot version the project targets,
   `run/main_scene` the scene that starts, `[autoload]` the global singletons and
   `[editor_plugins]` the enabled add-ons.
2. Read the scripts and scenes the task touches before changing them.

## Check the API, don't guess it

Most models were trained largely on Godot 3 code. Before using a class, method,
property or signal you aren't sure exists in Godot 4, look it up in the engine's own
reference:

```bash
godot --headless --doctool /tmp/godot-doc >/dev/null 2>&1   # once; ~7 MB of XML
grep -n 'name="move_and_slide"' /tmp/godot-doc/doc/classes/CharacterBody2D.xml
```

Classes are in `/tmp/godot-doc/doc/classes/<Class>.xml`, global functions and
constants (`print`, `randf_range`, `KEY_SPACE`) in `@GlobalScope.xml` there, and
GDScript annotations (`@export`, `@onready`) in
`/tmp/godot-doc/modules/gdscript/doc_classes/@GDScript.xml`.
Grep for the name; don't read whole files.

## Godot 3 code that breaks in Godot 4

| Godot 3 | Godot 4 |
| --- | --- |
| `KinematicBody2D` / `KinematicBody` | `CharacterBody2D` / `CharacterBody3D` |
| `move_and_slide(velocity, Vector2.UP)` | set the `velocity` property, then `move_and_slide()` with no arguments |
| `Spatial`, `Position2D`, `Sprite` (3D) | `Node3D`, `Marker2D`, `Sprite3D` |
| `export var x`, `onready var y`, `tool` | `@export var x`, `@onready var y`, `@tool` |
| `yield(obj, "signal")` | `await obj.signal` |
| `connect("pressed", self, "_on_pressed")` | `pressed.connect(_on_pressed)` |
| `emit_signal("hit", 5)` | `hit.emit(5)` (the old form still works) |
| `scene.instance()` | `scene.instantiate()` |
| `get_tree().change_scene("res://x.tscn")` | `get_tree().change_scene_to_file("res://x.tscn")` |
| `var x setget set_x` | `var x: int: set = set_x` (or an inline `set(value):` block) |
| `Tween` node, `interpolate_property` | `var t := create_tween()` then `t.tween_property(...)` |
| `File.new()`, `Directory.new()` | `FileAccess.open(...)`, `DirAccess.open(...)` |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` |
| `rand_range`, `deg2rad`, `stepify` | `randf_range`, `deg_to_rad`, `snapped` |
| `BUTTON_LEFT`, `KEY_SPACE` | `MOUSE_BUTTON_LEFT`, `KEY_SPACE` (enums moved; check the doc) |
| `rect_position`, `rect_size` on Controls | `position`, `size` |
| `Engine.editor_hint` | `Engine.is_editor_hint()` |
| `PoolStringArray`, `PoolVector2Array` | `PackedStringArray`, `PackedVector2Array` |

## Writing GDScript

- Type variables and function signatures (`var speed: float = 200.0`,
  `func hurt(amount: int) -> void:`). The editor and the checker catch more mistakes.
  Use either an explicit type or `:=`, never both: `var x: float := 1.0` is a parse
  error in every Godot 4 version.
- Movement and physics go in `_physics_process(delta)`, input that fires once in
  `_unhandled_input(event)`, per-frame visuals in `_process(delta)`.
- Get nodes with `@onready var sprite: Sprite2D = $Sprite2D`. A `$Path` that doesn't
  match the scene tree is null at runtime, so check the `.tscn` for the node's name.
- Prefer signals over child nodes calling up into their parents.
- Match the file's indentation (Godot's editor uses tabs). Mixing tabs and spaces in
  one file is a parse error.

## Scenes and project files

- `.tscn` and `.tres` are text, and small edits (a property value, a new node) are
  safe. Keep `[ext_resource]` ids and `load_steps` consistent if you add resources,
  and prefer building large node trees in the editor or in code.
- Don't edit `.import` files, `*.uid` files or anything in `.godot/`; Godot regenerates
  them.
- `project.godot` is safe for single settings; the editor rewrites it on save.

## Check your work

After editing scripts, parse each changed one:

```bash
godot --headless --path . --import 2>&1 | grep -E "ERROR|SCRIPT ERROR"   # first, so class_name types resolve
godot --headless --path . --check-only --script res://scripts/player.gd 2>&1 | grep -E "ERROR"
```

`--check-only` stops at the first error in a file, so run it again after each fix
until it prints nothing. Then run the game for a few seconds and read its output:

```bash
timeout 20 godot --path . --quit-after 600 2>&1 | grep -E "ERROR|WARNING" | head -30
```

## Seeing the game

When you can read images, render frames from the game itself, so no screen capture
is needed:

```bash
godot --path . --write-movie /tmp/godot-frames/shot.png --quit-after 120
```

This opens a window, runs 120 frames at a fixed 60 FPS and saves
`shot00000000.png`, `shot00000001.png` and so on, at the project's window size. Read
the last frame or two. It doesn't work with `--headless` (the engine crashes). To
show a specific moment, add a temporary scene or autoload that sets up the state, and
remove it afterwards. A screenshot of the desktop or the editor still needs the
user's permission first.

## Godot MCP add-on

`godot_mcp` (github.com/triforge0/godot-mcp) lets an agent drive the open editor
through 64 tools. It has two parts:

- **The plugin**, in `addons/godot_mcp/` with `plugin.cfg` directly inside it, and
  `res://addons/godot_mcp/plugin.cfg` in `[editor_plugins]` of `project.godot`.
  Upstream keeps it at `plugin/addons/godot_mcp/`; a checkout is in
  `~/Projects/godot-mcp/`. It connects to the server at `ws://127.0.0.1:6505/ws` and
  retries until it's up.
- **The server**, `godot-mcp start`, on PATH. opencode starts it from the project's
  `opencode.json`:

  ```json
  {"mcp": {"godot": {"type": "local", "command": ["godot-mcp", "start"]}}}
  ```

When the `godot` tools are available, call `project_info` first; it fails if the
editor isn't open with the plugin enabled, and then you should ask Ky to open the
project in Godot. Useful tools:

- Reading: `scene_current`, `node_list`, `node_children`, `node_get_property`,
  `class_inspect` (the live ClassDB, like the doc dump), `errors_list`,
  `console_logs`.
- Changing: `scene_open`, `node_create`, `node_set_property`, `script_attach`,
  `scene_save`. Prefer these to hand-editing `.tscn` files, and save the scene after.
- Running: `runtime_run`, `runtime_status`, `runtime_stop`, then `errors_list`.
- `screenshot_capture` of the running game is fine, like `--write-movie` frames; ask
  before capturing the editor itself.
- Avoid `script_execute` (arbitrary code in the editor) and the delete tools unless
  asked. The `skill_*` tools generate generic content; write the code yourself.

If the `godot` tools aren't available, use the files and the commands above. To add
the add-on to another project, ask first, then copy the plugin folder and add the
`opencode.json` entry.
