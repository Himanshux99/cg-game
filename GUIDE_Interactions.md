# Guide: Adding an Interaction (Press E)

This guide shows how to make any object in the game react when the player stands near it and presses **E**.

## How it works

Three pieces work together:

| Piece | File | Job |
|---|---|---|
| `InteractionArea` | `Interaction/Interaction Area/InteractionArea.tscn` (script: `Script/interactions/interaction_area.gd`) | An `Area2D` that detects the player. When the player walks in, it registers itself with the manager. When the player leaves, it unregisters. |
| `InteractionManager` | `Managers/interactionManager.gd` (autoload) | Keeps the list of areas the player is standing in, shows the **"Press [ ] to <action>"** label for the closest one, and listens for the `interact` input (E). |
| Your object's script | e.g. `Script/cafeDoor.gd` | Assigns a function to `interaction_area.interact`. That function is what runs on E. |

Flow: player enters area → area registers with `InteractionManager` → label shows → player presses **E** → manager calls `interact` on the closest area → your function runs.

The `interact` input action is already mapped to **E** in Project Settings → Input Map. You do not need to add it.

---

## Steps

### 1. Add the object to your scene

Use whatever node fits: `StaticBody2D`, `Node2D`, `AnimatedSprite2D`, etc. Give it a sprite and (if it should block the player) a collision shape.

### 2. Add an `InteractionArea` as a child

1. Select your object in the Scene dock.
2. Press **Ctrl+Shift+A** (Instantiate Child Scene) and pick `Interaction/Interaction Area/InteractionArea.tscn`.
3. Keep the node named `InteractionArea` (scripts below look it up by this name).

### 3. Give the area a shape

The area has no shape yet, so nothing will be detected.

1. Select `InteractionArea`, add a child **CollisionShape2D**.
2. Set its **Shape** (e.g. `RectangleShape2D` or `CircleShape2D`).
3. Size it **larger than the object** so the player can trigger it from a comfortable distance.

### 4. Set the prompt text

Select `InteractionArea` and, in the Inspector, set **Action Name** (e.g. `open`, `talk`, `use`). The label will read `Press [ ] to open`.

### 5. Attach a script to your object and hook up the function

Attach a script to the **parent object** (not to the `InteractionArea`) and assign a function to `interaction_area.interact` in `_ready()`:

```gdscript
extends StaticBody2D

@onready var interaction_area: InteractionArea = $InteractionArea


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")


func _on_interact() -> void:
	print("Player pressed E on me!")
```

Replace the body of `_on_interact()` with whatever should happen. That is all that is needed to wire the E button.

### 6. Test it

Run the scene, walk into the area, and check:

- The prompt label appears.
- Pressing **E** runs `_on_interact()`.
- Walking away hides the prompt.

---

## Common things to do inside `_on_interact()`

**Start a dialogue**

```gdscript
func _on_interact() -> void:
	Dialogue.start_dialogue_from_json("res://Dialogue/my_dialogue.json")
```

To run code when the dialogue finishes:

```gdscript
func _on_interact() -> void:
	if not Dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
		Dialogue.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
	Dialogue.start_dialogue_from_json("res://Dialogue/my_dialogue.json")


func _on_dialogue_ended() -> void:
	pass
```

**Open a puzzle** (see `Script/cafeDoor.gd`)

```gdscript
@export var puzzle_scene: PackedScene

func _on_interact() -> void:
	if puzzle_scene:
		PuzzleManager.open_puzzle(puzzle_scene)
```

Drag the puzzle `.tscn` onto the exported field in the Inspector.

**Change scene through a door** (see `Script/levelDoor.gd`)

```gdscript
SceneManager.enter_scene(target_scene, target_spawn_id, return_spawn_id)
```

**Give or check an inventory item**

```gdscript
InventoryManager.has_item("form")
```

**Remember a state across saves**

```gdscript
GameManager.object_changed("my_object_id", {"opened": true})   # save
SaveManager.get_object_state("my_object_id").get("opened", false)   # read
```

---

## Locking and unlocking an interaction

Set `enabled` on the area to turn the prompt and E press on or off at runtime:

```gdscript
interaction_area.enabled = false   # prompt hidden, E does nothing
interaction_area.enabled = true    # works again (if the player is inside, it re-registers)
```

`Script/inside_cafe.gd` uses this to keep an interaction locked until a condition is met.

---

## Async interactions

`InteractionManager` does `await active_areas[0].interact.call()`. While your function is running, no other interaction can start and the prompt is hidden. If your function uses `await` (for example, waiting for a dialogue or tween), the prompt comes back only when it finishes:

```gdscript
func _on_interact() -> void:
	Dialogue.start_dialogue_from_json("res://Dialogue/my_dialogue.json")
	await Dialogue.dialogue_ended
```

---

## Troubleshooting

| Problem | Likely cause |
|---|---|
| Prompt never appears | The `InteractionArea` has no `CollisionShape2D`, or the shape is too small or in the wrong place. |
| Prompt never appears (shape is fine) | The player must be on collision layer 2 (it is, by default: layer = 3) and the area's **Collision Mask** must include layer 2. The `InteractionArea.tscn` scene already sets this. Don't change it. |
| Prompt appears but E does nothing | You forgot `interaction_area.interact = Callable(self, "_on_interact")` in `_ready()`, or the function name doesn't match. |
| Error: `Node not found: InteractionArea` | The child node was renamed. Keep it named `InteractionArea`, or update the `$InteractionArea` path in your script. |
| Prompt shows the wrong text | Check **Action Name** on the `InteractionArea` node in the Inspector. |
| Prompt appears after the interaction is meant to be locked | Set `interaction_area.enabled = false` in `_ready()` until the unlock condition is met. |
| Two objects overlap and the wrong one triggers | The manager picks the **closest** area to the player. Move the objects or shrink the shapes. |
| Nothing works in a brand new scene | `InteractionManager` is an autoload, so it needs no setup. Make sure the scene has the player (`Scene/player.tscn`), which is in the `Player` group. |

## Quick checklist

- [ ] Object has an `InteractionArea` child (named `InteractionArea`)
- [ ] `InteractionArea` has a `CollisionShape2D` with a shape
- [ ] **Action Name** is set
- [ ] Parent script sets `interaction_area.interact = Callable(self, "_on_interact")` in `_ready()`
- [ ] `_on_interact()` does the thing
