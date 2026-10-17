# Level Door Guide

The Level Door moves the player from one scene to another when they press **E** on it. It is a small script, [Script/levelDoor.gd](Script/levelDoor.gd), that you attach to a node or drop in as the ready-made scene [Scene/levelDoor.tscn](Scene/levelDoor.tscn).

It works with three other pieces:

| Piece | Role |
|---|---|
| `InteractionArea` | Detects the player and fires the interaction when E is pressed. The door needs one. |
| `SceneManager` (autoload) | Changes the scene and remembers where the player came from. |
| `SpawnPoint` ([Script/interactions/spawn_point.gd](Script/interactions/spawn_point.gd)) | A marker with an id. It tells the player where to appear in the new scene. |

---

## Parameters

All of these are set in the Inspector on the node that has `levelDoor.gd`.

### `target_scene_path`
- **Type:** file path to a `.tscn`. Use the file picker.
- **Used on:** entry doors.
- **What it does:** the scene to load when the player uses the door.
- If it is empty and `is_return_door` is off, nothing happens: no sound and no scene change.

### `target_spawn_id`
- **Type:** String. Default is `"default"`.
- **Used on:** entry doors.
- **What it does:** the `spawn_id` of the `SpawnPoint` in the **target** scene where the player appears.
- If no `SpawnPoint` with that id exists, the player stays at their default position and the game prints a warning: `No SpawnPoint with id '...' found in current scene`.

### `return_spawn_id`
- **Type:** String. Default is `""`.
- **Used on:** entry doors.
- **What it does:** the `spawn_id` of a `SpawnPoint` in the **current** scene, right in front of this door. When the player comes back through a return door, they appear there.
- If you leave it empty, the player returns to the scene but is not moved to any spawn point.

### `is_return_door`
- **Type:** bool. Default is off.
- **Used on:** exit doors, such as the door inside a building.
- **What it does:** when checked, the door ignores `target_scene_path` and sends the player back to the scene they entered from. They land on that door's `return_spawn_id`.
- It only works if the player got there through an entry door. `SceneManager` records the way back only when a door uses `enter_scene`. If there is no recorded scene, the door does nothing.

### `door_sound`
- **Type:** AudioStream. Default is `Assets/Sound/Door.mp3`.
- **What it does:** the sound played when the door is used.
- The sound keeps playing across the scene change.
- Set it to empty to make the door silent.

### `door_volume_db`
- **Type:** float. Default is `0.0`.
- **What it does:** the sound volume in decibels. `0` is full volume and negative values are quieter, for example `-10`.

### `door_sound_start_time`
- **Type:** float, in seconds. Default is `0.0`.
- **What it does:** skips this many seconds at the start of the sound. Use it if the audio file has silence before the door noise.

---

## Setup: an entry door and a return door

Example: a building's front door in the outdoor scene (`Outside.tscn`) leading to the building's inside scene (`Inside.tscn`).

### 1. Outdoor scene: the entry door

1. Add a node for the door, such as a `StaticBody2D` with a sprite and a collision shape.
2. Add an `InteractionArea` as a **child** of it, or make the door a child of an `InteractionArea`. The script looks in both places. If it finds neither, it prints `LevelDoor '...' has no InteractionArea`.
3. Attach `levelDoor.gd` to the door node, or instance `Scene/levelDoor.tscn` as a child of the `InteractionArea` node.
4. Add a `SpawnPoint` in front of the door and set its `spawn_id` to `BuildingOutside`.
5. Set the door's parameters:

| Parameter | Value |
|---|---|
| `target_scene_path` | `Inside.tscn` |
| `target_spawn_id` | `BuildingInside` |
| `return_spawn_id` | `BuildingOutside` |

### 2. Indoor scene: the exit door

1. Add a `SpawnPoint` near the entrance with `spawn_id` = `BuildingInside`.
2. Add the exit door with an `InteractionArea` and the level door script. This is how `ExitDoor` is built in [Scene/InsideCafe.tscn](Scene/InsideCafe.tscn).
3. Set the door's parameters:

| Parameter | Value |
|---|---|
| `is_return_door` | on |

Leave the other parameters alone. The player goes back to `Outside.tscn` and appears at `BuildingOutside`.

### What happens at runtime

1. The player presses E on the entry door.
2. The door sound plays.
3. `SceneManager.enter_scene()` stores the current scene and `return_spawn_id`, then loads `Inside.tscn`.
4. `Player.gd` finds the `SpawnPoint` with id `BuildingInside` and moves the player there.
5. The player presses E on the exit door.
6. `SceneManager.go_back()` reloads `Outside.tscn` and places the player at `BuildingOutside`.

---

## Examples already in the project

| Door | Scene | Setup |
|---|---|---|
| `CollegeEntry` | [Scene/Part-1.tscn](Scene/Part-1.tscn) | `target_spawn_id = "Part-2_spawn"`, `return_spawn_id = "part-2_respawn"` |
| Admin Building door | [Scene/Part-2.tscn](Scene/Part-2.tscn) | `target_spawn_id = "AdminBuildingInside"`, `return_spawn_id = "AdminBuildingOutside"` |
| `ExitDoor` | [Scene/InsideCafe.tscn](Scene/InsideCafe.tscn) | `is_return_door = true` |

---

## Troubleshooting

| Problem | Likely cause |
|---|---|
| Pressing E does nothing | The door has no `InteractionArea`, or `target_scene_path` is empty and `is_return_door` is off. |
| Player appears at the wrong spot | The `spawn_id` is misspelled. It is case-sensitive: `part-2_respawn` is not `Part-2_respawn`. |
| Console warning "No SpawnPoint with id..." | The target scene has no `SpawnPoint` with that id. |
| Return door does nothing | The player did not arrive through an entry door, for example you started the game directly in that scene. |
| Player returns to the right scene but the wrong spot | `return_spawn_id` is empty, or it names a `SpawnPoint` that doesn't exist in the entry scene. |
| No door sound | `door_sound` is empty, `door_volume_db` is very low, or `door_sound_start_time` is past the end of the clip. |

## Rules to remember

- `target_spawn_id` is a spawn point in the scene you are going to.
- `return_spawn_id` is a spawn point in the scene you are leaving.
- A door that leads outward only needs `is_return_door` checked.
- Spawn ids must match exactly. Case counts.
