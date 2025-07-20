extends Area2D
class_name NullEnemy

func _ready():
	%Timer.start(randf_range(0,10))
	

func _on_body_entered(body):
	if body is Player:
		body.trigger_death() 

func _on_timer_timeout():
	%AnimatedSprite2D.play("default")
	%Timer.start(randf_range(5,10))

func get_tile_info() -> TileInfo:
	return TileInfo.new(TileInfo.TileType.ENEMY, "null")
