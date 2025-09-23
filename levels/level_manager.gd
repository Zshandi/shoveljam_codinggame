extends Node
class_name Levels

@export
var level_list: Array[LevelInfo] = []

var editor = null
var controls = null
var level_node = null

func _ready() -> void:
	editor = get_tree().get_first_node_in_group(&"Editor")
	controls = get_tree().get_first_node_in_group(&"Controls")
	level_node = get_tree().get_first_node_in_group(&"level")
	if level_node == null: return
	load_level(0)

var current_level: int = -1

func load_next():
	load_level(current_level + 1)

func load_current():
	load_level(current_level)
	
func load_level(level_index: int):
	if level_node == null: return
	for child in level_node.get_children():
		child.queue_free()
		
	var level_data := level_list[level_index]
	var level := level_data.scene.instantiate()
	if current_level != level_index:
		controls.reset_state()

		var level_text := level_data.description
		level_text = "# " + level_text.replace("\n", "\n# ") + "\n"

		editor.text = level_text
		controls.starting_code = editor.text
		editor.set_caret_line(editor.get_line_count())
	current_level = level_index
	level_node.call_deferred("add_child", level)
	
func update_enemies(start, goal):
	if level_node == null: return
	var enemies = get_tree().get_nodes_in_group("race")
	for e in enemies:
		e._on_player_move(start, goal)
