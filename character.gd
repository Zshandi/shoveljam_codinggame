extends CharacterBody2D

const TILE_WIDTH = 16

enum Direction {
	RIGHT,
	DOWN,
	LEFT,
	UP
}

@export
var movement_speed := 25

var user_variables:Dictionary = {}

func _ready() -> void:
	var controls = get_tree().get_first_node_in_group(&"Controls")
	controls.context = self

func _physics_process(delta: float) -> void:
	move_and_slide()

func move(direction:Direction, num_tiles:int = 1) -> String:
	velocity = Vector2.RIGHT.rotated(direction * PI/2)*movement_speed
	await get_tree().create_timer((float(num_tiles*TILE_WIDTH)/movement_speed)).timeout
	velocity = Vector2.ZERO
	return "Moved %d tile%s to the %s" % [num_tiles,"" if num_tiles == 1 else "s", Direction.keys()[direction]]
	
func grab() -> String:
	return "not implemented... yet!"
	
func use(item) -> String:
	return "not implemented... yet!"
