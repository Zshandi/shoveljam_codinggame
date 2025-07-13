extends CharacterBody2D

const TILE_WIDTH = 32

@export
var movement_speed := 50

var user_variables:Dictionary = {}

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	move_and_slide()

func move(tiles:int, direction:float):
	velocity = Vector2(cos(deg_to_rad(direction)),-sin(deg_to_rad(direction)))*movement_speed
	await get_tree().create_timer((float(tiles*TILE_WIDTH)/movement_speed)).timeout
	velocity = Vector2.ZERO
