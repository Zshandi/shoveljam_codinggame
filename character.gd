extends CharacterBody2D

@export
var movement_amount := 60

@export
var movement_time := 0.2

@export
var jump_speed := 600

var movement_speed := 0.0

var user_variables:Dictionary = {}

func _ready() -> void:
	movement_speed = movement_amount / movement_time

func _physics_process(delta: float) -> void:
	velocity.y += get_gravity().y
	move_and_slide()

func jump(force:float = jump_speed) -> void:
	velocity.y = -force

func move_left(amount:float = 1) -> void:
	await move(-amount)

func move_right(amount:float = 1) -> void:
	await move(amount)

func move(dir_amount:float):
	velocity.x = movement_speed * sign(dir_amount)
	await get_tree().create_timer(0.25 * abs(dir_amount)).timeout
	velocity.x = 0
