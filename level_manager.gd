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
	},
	{
		"scene" : preload("res://levels/level_6.tscn"),
		"text" : "# If you haven't been using repeats yet, this is a good time to start!\n"
	},
	{
		"scene" : preload("res://levels/level_7.tscn"),
		"text" : "# Race conditions are nasty errors! They move unpredictably every time you move\nRemember, you can check to see if a nearby tile has an error in it before you move there!\n"
	},
	{
		"scene" : preload("res://levels/level_8.tscn"),
		"text" : "# While loops are useful when you want to loop but don't know how many you will need\n"
	},
	{
		"scene" : preload("res://levels/level_9.tscn"),
		"text" : "# If this level is taking too long to run, check out the docs on how to increase the execution speed\n"
	},
	{
		"scene" : preload("res://levels/level_10.tscn"),
		"text" : "# If you can reach the end of this one, you've truly mastered writing code!\n"
	}
]


var editor = null
var controls = null
var level_node = null

func _ready() -> void:
	editor = get_tree().get_first_node_in_group(&"Editor")
	controls = get_tree().get_first_node_in_group(&"Controls")
	level_node = get_tree().get_first_node_in_group(&"level")
	load_next()

var current_level:int = -1

func load_next():
	current_level += 1
	var level_data = level_list[current_level]
	controls.reset_state()
	editor.text = level_data["text"]
	editor.set_caret_line(editor.get_line_count())

func load_current():
	for child in level_node.get_children():
		child.queue_free()
		
	var level_data = level_list[current_level]
	var level = level_data["scene"].instantiate()
	level_node.call_deferred("add_child",level)
