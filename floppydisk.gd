extends Area2D
class_name FloppyDisk

func _on_body_entered(body):
	if body is Player:
		body.trigger_victory() 
