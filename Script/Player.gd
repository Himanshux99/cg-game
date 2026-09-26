extends CharacterBody2D

@export var SPEED := 300.0
@export var ACCELERATION := 1200.0
@export var FRICTION := 1500.0
var last_direction = Vector2.RIGHT
#const direction = Vector2.RIGHT
@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D
@onready var silhouette_sprite: AnimatedSprite2D = $SilhouetteSprite

func _ready() -> void:
	_apply_pending_spawn_point()
	GameManager.register_player(self)

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
