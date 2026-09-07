extends CharacterBody2D

@export var SPEED := 300.0
@export var ACCELERATION := 1200.0
@export var FRICTION := 1500.0
var last_direction = Vector2.RIGHT
#const direction = Vector2.RIGHT
@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	GameManager.register_player(self)

func _physics_process(delta: float) -> void:
	player_movement(delta)
	process_animation()
	move_and_slide()

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
