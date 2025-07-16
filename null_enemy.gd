extends Area2D

func _ready():
	%Timer.start(randf_range(0,10))

func _on_body_entered(body):
	if body is Player:
		body.trigger_death() 


func _on_timer_timeout():
	%AnimatedSprite2D.play("default")
	%Timer.start(randf_range(5,10))
