extends CharacterBody2D

@export var SPEED := 300.0
@export var ACCELERATION := 1200.0
@export var FRICTION := 1500.0
var last_direction = Vector2.RIGHT
#const direction = Vector2.RIGHT
@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D

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
	if velocity != Vector2.ZERO:
		play_animation("running_",last_direction)
	else:
		play_animation("idle_",last_direction)
