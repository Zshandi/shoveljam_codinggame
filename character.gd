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
signal player_move

@export var movement_speed = 50

var user_variables: Dictionary = {}
var dead = false
var moving = false
var distance_travelled = 0.0
var goal_position: Vector2
var goal_distance: float

func _ready() -> void:
	var controls = get_tree().get_first_node_in_group(&"Controls")
	controls.context = self

func _physics_process(_delta: float) -> void:
	if moving:
		var initial_position = global_position
		move_and_slide()
		distance_travelled += abs((global_position - initial_position).length())
		if distance_travelled >= goal_distance:
			moving = false
			global_position = goal_position
		

func _get_move_vector(direction: Direction) -> Vector2:
	var dir_vector = Vector2.RIGHT.rotated(direction * PI / 2)
	return dir_vector * TILE_WIDTH

func check_move(direction: Direction) -> TileInfo:
	var move_vector = _get_move_vector(direction)
	var new_position: Vector2 = global_position + move_vector
	
	var space_state = get_world_2d().direct_space_state
	var query_parameters := PhysicsPointQueryParameters2D.new()
	query_parameters.position = new_position
	query_parameters.collide_with_areas = true
	query_parameters.exclude = [self] # Exclude self from collisions
	
	print_debug("new_position: ", new_position)
	print_debug("floppy: ", get_node("../FloppyDisk").global_position)
	
	var result = space_state.intersect_point(query_parameters)
	for intersection in result:
		var what = intersection.collider
		if what.has_method("get_tile_info"):
			var tile_info = what.get_tile_info()
			if tile_info is TileInfo: return tile_info
		else:
			# No tile info then it's a wall
			return TileInfo.new(TileInfo.TileType.WALL)
	
	# No collision then it's empty
	return TileInfo.new(TileInfo.TileType.EMPTY)

func move(direction: Direction) -> TileInfo:
	get_tree().root.get_child(0)
	distance_travelled = 0.0
	goal_distance = TILE_WIDTH
	var move_vector = _get_move_vector(direction)
	var move_result := check_move(direction)
	var speed = movement_speed * ((Options.code_execution_speed / 2.0) + 0.5)
	goal_position = global_position + move_vector
	velocity = move_vector.normalized() * speed
	%MoveTimer.start(goal_distance / speed)
	moving = true
	await %MoveTimer.timeout
	moving = false
	player_move.emit(global_position, goal_position)
	LevelManager.update_enemies(global_position, goal_position)
	velocity = Vector2.ZERO
	return move_result
	
func load_level_num(level: int):
	level = clamp(level, 0, len(LevelManager.level_list) - 1)
	LevelManager.load_level(level)

func skip_level():
	LevelManager.load_next()

func get_level_num() -> int:
	return LevelManager.currently_loaded_level

func grab() -> String:
	return "not implemented... yet!"
	
func use(_item) -> String:
	return "not implemented... yet!"
	
func reset_player():
	dead = false
	%AnimatedSprite2D.play("blink")
	%AnimTimer.start(randf_range(5, 10))
	
func trigger_death():
	player_death.emit()
	dead = true
	%AnimatedSprite2D.play("death")
	%MoveTimer.stop()
	%MoveTimer.emit_signal("timeout")
	
func trigger_victory():
	LevelManager.level_complete()


func _on_timer_timeout():
	if not dead:
		%AnimatedSprite2D.play("blink")
		%AnimTimer.start(randf_range(5, 10))
		
func _exit_tree():
	%MoveTimer.timeout.emit()

# These are necessary due to Expression not having these available
# It also doesn't have is operator... I think we'll have to move to something different eventually...

func range(a, b=null, c=null) -> Array:
	if b == null:
		return range(a)
	elif c == null:
		return range(a, b)
	else:
		return range(a, b, c)

func len(x) -> int:
	return len(x)
