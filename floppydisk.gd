extends Area2D
class_name FloppyDisk

func _on_body_entered(body):
	if body is Player:
		body.trigger_victory() 

func get_tile_info() -> TileInfo:
	return TileInfo.new(TileInfo.TileType.FLOPPY)
