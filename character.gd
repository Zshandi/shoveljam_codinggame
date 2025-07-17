extends CharacterBody2D
class_name Player
const TILE_WIDTH = 16

enum Direction {
	RIGHT,
	DOWN,
	LEFT,
	UP
}

signal player_death

@export var movement_speed = 50

var user_variables:Dictionary = {}
var dead = false

func _ready() -> void:
	var controls = get_tree().get_first_node_in_group(&"Controls")
	controls.context = self
	player_death.connect(controls.on_player_death)

func _physics_process(delta: float) -> void:
	move_and_slide()

func move(direction:Direction, num_tiles:int = 1) -> String:
	var distance = abs(float(num_tiles*TILE_WIDTH))
	var initial_position = global_position
	var angle = Vector2.RIGHT.rotated(direction * PI/2)*sign(num_tiles)
	velocity = angle*movement_speed
	%MoveTimer.start(distance/movement_speed)
	await %MoveTimer.timeout
	velocity = Vector2.ZERO
	global_position = initial_position+(angle*distance)
	return "Moved %d tile%s %s" % [num_tiles,"" if num_tiles == 1 else "s", Direction.keys()[direction]]
	
func grab() -> String:
	return "not implemented... yet!"
	
func use(item) -> String:
	return "not implemented... yet!"
	
func trigger_death():
	emit_signal("player_death","null")
	dead = true
	%AnimatedSprite2D.play("death")
	%MoveTimer.stop()
	%MoveTimer.emit_signal("timeout")


func _on_timer_timeout():
	if not dead:
		%AnimatedSprite2D.play("blink")
		%AnimTimer.start(randf_range(5,10))
