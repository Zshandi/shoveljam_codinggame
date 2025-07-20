extends Node2D
class_name Levels

var level_list := [
	{
		"scene" : preload("res://levels/level_1.tscn"),
		"text" : "# Collect the floppy disk by calling move() the correct number of times\n# See the Docs for help\n"
	},
	{
		"scene" : preload("res://levels/level_2.tscn"),
		"text" : "# You will need to move in multiple directions to get this one\n"
	},
	{
		"scene" : preload("res://levels/level_3.tscn"),
		"text" : "# Watch out for null references, they will make you crash!\n"
	},
	{
		"scene" : preload("res://levels/level_4.tscn"),
		"text" : "# Repeats can help you move farther with less lines of code!\n"
	},
	{
		"scene" : preload("res://levels/level_5.tscn"),
		"text" : "# Can you move diagonally?\n"
	}
]


var editor = null
var controls = null

func _ready() -> void:
	editor = get_tree().get_first_node_in_group(&"Editor")
	controls = get_tree().get_first_node_in_group(&"Controls")
	load_next()

var current_level:int = -1

func load_next():
	current_level += 1
	var level_data = level_list[current_level]
	controls.reset_state()
	editor.text = level_data["text"]
	editor.set_caret_line(editor.get_line_count())

func load_current():
	for child in get_children():
		child.queue_free()
		
	var level_data = level_list[current_level]
	
	var level = level_data["scene"].instantiate()
	
	call_deferred("add_child",level)
