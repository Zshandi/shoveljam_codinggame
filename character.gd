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
signal player_move

@export var movement_speed = 50

var user_variables:Dictionary = {}
var dead = false
var moving = false
var distance_travelled = 0.0
var goal_position:Vector2
var goal_distance:float

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
		

func _get_move_vector(direction:Direction) -> Vector2:
	var dir_vector = Vector2.RIGHT.rotated(direction * PI/2)
	return dir_vector*TILE_WIDTH

func check_move(direction:Direction) -> TileInfo:
	var move_vector := _get_move_vector(direction) * 0.999
	var move_result:KinematicCollision2D = null
	if test_move(transform, move_vector, move_result):
		if move_result != null:
			var what = move_result.get_collider()
			if what.has_method("get_tile_info"):
				var tile_info =  what.get_tile_info()
				if tile_info is TileInfo: return tile_info
		# Does not have TileInfo, then must be a wall
		return TileInfo.new(TileInfo.TileType.WALL)
	# No collision then it's empty
	return TileInfo.new(TileInfo.TileType.EMPTY)

func move(direction:Direction) -> TileInfo:
	distance_travelled = 0.0
	goal_distance = TILE_WIDTH
	var move_vector = _get_move_vector(direction)
	var move_result := check_move(direction)
	goal_position = global_position + move_vector
	velocity = move_vector.normalized() * movement_speed
	%MoveTimer.start(goal_distance/movement_speed)
	moving = true
	await %MoveTimer.timeout
	moving = false
	emit_signal("player_move",global_position,goal_position)
	velocity = Vector2.ZERO
	return move_result
	
func goto_level(level:int):
	level = clamp(level-1,0,9)
	LevelManager.load_level(level)
	
func grab() -> String:
	return "not implemented... yet!"
	
func use(item) -> String:
	return "not implemented... yet!"
	
func reset_player():
	dead = false
	%AnimatedSprite2D.play("blink")
	%AnimTimer.start(randf_range(5,10))
	
func trigger_death():
	emit_signal("player_death")
	dead = true
	%AnimatedSprite2D.play("death")
	%MoveTimer.stop()
	%MoveTimer.emit_signal("timeout")
	
func trigger_victory():
	LevelManager.load_next()


func _on_timer_timeout():
	if not dead:
		%AnimatedSprite2D.play("blink")
		%AnimTimer.start(randf_range(5,10))
		
func _exit_tree():
	%MoveTimer.timeout.emit()
