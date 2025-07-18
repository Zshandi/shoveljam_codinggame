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
signal player_victory

@export var movement_speed = 50

var user_variables:Dictionary = {}
var dead = false
var moving = false
var distance_travelled = 0.0
var goal_position
var goal_distance

func _ready() -> void:
	var controls = get_tree().get_first_node_in_group(&"Controls")
	controls.context = self

func _physics_process(delta: float) -> void:
	if moving:
		var initial_position = global_position
		move_and_slide()
		distance_travelled += abs((global_position-initial_position).length())
		if distance_travelled >= goal_distance:
			moving = false
			global_position = goal_position
		

func move(direction:Direction) -> String:
	var num_tiles = 1
	distance_travelled = 0.0
	goal_distance = abs(float(num_tiles*TILE_WIDTH))
	var angle = Vector2.RIGHT.rotated(direction * PI/2)*sign(num_tiles)
	goal_position = global_position+(angle*goal_distance)
	velocity = angle*movement_speed
	%MoveTimer.start(goal_distance/movement_speed)
	moving = true
	await %MoveTimer.timeout
	moving = false
	velocity = Vector2.ZERO
	return "Moved %d tile%s %s" % [num_tiles,"" if num_tiles == 1 else "s", Direction.keys()[direction]]
	
func grab() -> String:
	return "not implemented... yet!"
	
func use(item) -> String:
	return "not implemented... yet!"
	
func trigger_death():
	emit_signal("player_death")
	dead = true
	%AnimatedSprite2D.play("death")
	%MoveTimer.stop()
	%MoveTimer.emit_signal("timeout")
	
func trigger_victory():
	emit_signal("player_victory")
	


func _on_timer_timeout():
	if not dead:
		%AnimatedSprite2D.play("blink")
		%AnimTimer.start(randf_range(5,10))
