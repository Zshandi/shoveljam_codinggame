extends TileMapLayer

func _ready():
	var tile_data = get_used_cells_by_id(1,Vector2i(1,0))
	# checkerboard pattern
	for tile in tile_data:
		if (tile.x+tile.y)%2 == 1:
			set_cell(tile,1,Vector2i(2,0))  
