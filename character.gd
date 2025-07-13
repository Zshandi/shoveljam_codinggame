extends CharacterBody2D

const TILE_WIDTH = 32

enum Direction {
	RIGHT,
	DOWN,
	LEFT,
	UP
}

@export
var movement_speed := 50

var user_variables:Dictionary = {}

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	move_and_slide()

func move(direction:Direction = Direction.RIGHT, num_tiles:int = 1):
	velocity = Vector2.RIGHT.rotated(direction * PI/2)*movement_speed
	await get_tree().create_timer((float(num_tiles*TILE_WIDTH)/movement_speed)).timeout
	velocity = Vector2.ZERO
