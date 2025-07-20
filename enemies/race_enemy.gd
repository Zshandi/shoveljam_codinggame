extends Area2D
class_name RaceEnemy

var tilemap
var allowed_tiles = [
	Vector2i(1,0),
	Vector2i(2,0)
]

func _ready():
	%Timer.start(randf_range(0,5))
	var controls = get_tree().get_first_node_in_group(&"Controls")
	controls.context.player_move.connect(_on_player_move)
	print(is_connected("player_move",_on_player_move))
	

func _on_body_entered(body):
	if body is Player:
		body.trigger_death() 

func _on_timer_timeout():
	%AnimatedSprite2D.play("default")
	%Timer.start(randf_range(2,5))

func get_tile_info() -> TileInfo:
	return TileInfo.new(TileInfo.TileType.ENEMY, "race")
	
func _on_player_move(player_initial,player_goal) -> void:
	tilemap = get_tree().get_first_node_in_group(&"tilemap")
	player_initial = tilemap.local_to_map(player_initial)
	player_goal = tilemap.local_to_map(player_goal)
	var tilemap_position = tilemap.local_to_map(position)
	var neighbors = tilemap.get_surrounding_cells(tilemap_position)
	neighbors.erase(player_goal)
	neighbors.shuffle()
	# find a nearby tile that is empty and is not the player's goal position
	for tile in neighbors:
		var tile_id = tilemap.get_cell_atlas_coords(tile)
		if tile_id in allowed_tiles:
			var tween = get_tree().create_tween()
			tween.tween_property(self,"position",tilemap.map_to_local(tile),0.2)
			
