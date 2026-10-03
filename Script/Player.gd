extends CharacterBody2D

@export var SPEED := 300.0
@export var ACCELERATION := 1200.0
@export var FRICTION := 1500.0
var last_direction = Vector2.RIGHT
#const direction = Vector2.RIGHT
@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D
@onready var silhouette_sprite: AnimatedSprite2D = $SilhouetteSprite

## Moving slower than this (px/s) doesn't count as walking, so no footsteps play.
const FOOTSTEP_MIN_SPEED := 10.0
## Random pitch range per step (1.0 = original sound).
const FOOTSTEP_PITCH_MIN := 0.50
const FOOTSTEP_PITCH_MAX := 1.10
## Each step is randomly quieter by up to this c:\Users\vk448\Downloads\Footstep_Tile_Left.mp3many dB.
const FOOTSTEP_VOLUME_VARIATION_DB := 2.0

# Footsteps: the first Timer sets the step interval, the first AudioStreamPlayer(2D) is the sound
## Seconds to skip at the start of the footstep sound, to cut leading silence
## so the step is heard right when the foot lands.
@export var footstep_start_time := 0.5

## When the player stops, the playing step fades out over this many seconds.
const FOOTSTEP_FADE_TIME := 0.12
const FOOTSTEP_FADE_TO_DB := -40.0

var footstep_timer: Timer
var footstep_audio: Node
var footstep_base_volume_db := 0.0
var footstep_fade_tween: Tween

func _ready() -> void:
	_apply_pending_spawn_point()
	_find_footstep_nodes()
	GameManager.register_player(self)

func _find_footstep_nodes() -> void:
	for child in get_children():
		if child is Timer and footstep_timer == null:
			footstep_timer = child
		elif (child is AudioStreamPlayer or child is AudioStreamPlayer2D) and footstep_audio == null:
			footstep_audio = child
	if footstep_timer == null or footstep_audio == null:
		push_warning("Player: add a Timer and an AudioStreamPlayer as children for footsteps")
	else:
		footstep_timer.one_shot = true
		# The volume set in the Inspector is the base; steps vary around it
		footstep_base_volume_db = footstep_audio.volume_db

func _update_footsteps() -> void:
	if footstep_timer == null or footstep_audio == null:
		return
	var moving := velocity.length() > FOOTSTEP_MIN_SPEED
	if not moving:
		_fade_out_footstep()
		return
	# One step sound each time the timer runs out, only while actually moving
	if footstep_timer.is_stopped():
		_cancel_footstep_fade()
		# Slightly different pitch (and volume) each step so it doesn't sound repetitive
		footstep_audio.pitch_scale = randf_range(FOOTSTEP_PITCH_MIN, FOOTSTEP_PITCH_MAX)
		footstep_audio.volume_db = footstep_base_volume_db + randf_range(-FOOTSTEP_VOLUME_VARIATION_DB, 0.0)
		footstep_audio.play(footstep_start_time)
		footstep_timer.start()

## Quickly fades the sound that's still playing when the player stops, instead of cutting it.
func _fade_out_footstep() -> void:
	if not footstep_audio.playing:
		return
	if footstep_fade_tween and footstep_fade_tween.is_valid():
		return  # already fading
	footstep_fade_tween = create_tween()
	footstep_fade_tween.tween_property(footstep_audio, "volume_db", footstep_base_volume_db + FOOTSTEP_FADE_TO_DB, FOOTSTEP_FADE_TIME)
	footstep_fade_tween.tween_callback(footstep_audio.stop)

func _cancel_footstep_fade() -> void:
	if footstep_fade_tween and footstep_fade_tween.is_valid():
		footstep_fade_tween.kill()

func _apply_pending_spawn_point() -> void:
	var spawn_id := SceneManager.consume_pending_spawn_id()
	if spawn_id.is_empty():
		return

	var spawn_point := _find_spawn_point(get_tree().current_scene, spawn_id)
	if spawn_point:
		global_position = spawn_point.global_position
	else:
		push_warning("No SpawnPoint with id '%s' found in current scene" % spawn_id)

func _find_spawn_point(node: Node, spawn_id: String) -> SpawnPoint:
	for child in node.get_children():
		if child is SpawnPoint and child.spawn_id == spawn_id:
			return child
		var found := _find_spawn_point(child, spawn_id)
		if found:
			return found
	return null

func _physics_process(delta: float) -> void:
	# Continuously copy the texture/animation configuration to the silhouette
	# Match the active animation sheet
	if silhouette_sprite.animation != animatedSprite2D.animation:
		silhouette_sprite.animation = animatedSprite2D.animation
		
	# Match the specific frame and visual mirroring
	silhouette_sprite.frame = animatedSprite2D.frame
	silhouette_sprite.flip_h = animatedSprite2D.flip_h
	silhouette_sprite.flip_v = animatedSprite2D.flip_v
	
	# Sync structural offsets if you use them
	silhouette_sprite.offset = animatedSprite2D.offset
	player_movement(delta)
	process_animation()
	move_and_slide()
	_update_footsteps()

func set_behind_wall(is_behind: bool) -> void:
	silhouette_sprite.visible = is_behind

func player_movement(delta: float) -> void:
	var input_dir = Input.get_vector("left","right","up","down");
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * SPEED, ACCELERATION * delta)
		last_direction = input_dir
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)


func play_animation(prifix:String,dir:Vector2) -> void:
	if dir.x != 0:
		animatedSprite2D.flip_h = dir.x<0
		animatedSprite2D.play(prifix+"right")
	elif dir.y<0:
		animatedSprite2D.play(prifix+"up")
	else:
		animatedSprite2D.play(prifix+"down")


func process_animation() -> void:
	var animation_name: String

	if velocity != Vector2.ZERO:
		animation_name = "running_"
	else:
		animation_name = "idle_"

	if last_direction.x != 0:
		animatedSprite2D.flip_h = last_direction.x < 0
		animation_name += "right"
	elif last_direction.y < 0:
		animation_name += "up"
	else:
		animation_name += "down"

	if animatedSprite2D.animation != animation_name:
		animatedSprite2D.play(animation_name)
