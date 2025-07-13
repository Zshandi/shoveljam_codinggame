extends Node2D
class_name Levels

var level_list := [
	preload("res://level_1.tscn")
]

func _ready() -> void:
	load_current()

var current_level:int = 0

func load_next():
	current_level = current_level + 1
	
	load_current()

func load_current():
	for child in get_children():
		child.queue_free()
	
	var level = level_list[current_level].instantiate()
	
	add_child(level)
