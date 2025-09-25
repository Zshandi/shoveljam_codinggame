extends Node
class_name Levels

@export
var level_list: Array[LevelInfo] = []

var editor: CodeUnedit = null
var controls = null
var level_node = null

var currently_loaded_level: int = -1

func _ready() -> void:
	editor = get_tree().get_first_node_in_group(&"Editor")
	controls = get_tree().get_first_node_in_group(&"Controls")
	level_node = get_tree().get_first_node_in_group(&"level")

	editor.text_changed.connect(deferred_code_save)
	code_save_deferred_timer.timeout.connect(code_save)
	code_save_maximum_timer.timeout.connect(code_save_maximum_timeout)

	if level_node == null: return
	load_level(SaveManager.current_level)

func load_next():
	load_level(currently_loaded_level + 1)

func level_complete() -> void:
	code_save()
	SaveManager.level_save_data[currently_loaded_level].level_completed = true
	load_next()

func load_current():
	load_level(currently_loaded_level)
	
func load_level(level_index: int):
	code_save()
	if level_node == null: return
	for child in level_node.get_children():
		child.queue_free()
		
	var level_data := level_list[level_index]
	var level := level_data.scene.instantiate()
	if currently_loaded_level != level_index:
		controls.reset_state()

		var level_text := level_data.description
		level_text = "# " + level_text.replace("\n", "\n# ") + "\n"

		if level_index in SaveManager.level_save_data:
			editor.text = SaveManager.level_save_data[level_index].previous_code
			print_debug("Loaded code: ", SaveManager.level_save_data[level_index].previous_code)
			if editor.text == "":
				editor.text = level_text
		else:
			editor.text = level_text
		
		controls.starting_code = level_text
		editor.set_caret_line(editor.get_line_count())
	
	currently_loaded_level = level_index

	SaveManager.current_level = level_index
	SaveManager.write_save_data()

	level_node.call_deferred("add_child", level)

var is_code_save_deferred: bool = false
@onready
var code_save_deferred_timer: Timer = %CodeSaveDeferredTimer
@onready
var code_save_maximum_timer: Timer = %CodeSaveMaximumTimer
func deferred_code_save():
	code_save_deferred_timer.stop()
	code_save_deferred_timer.start(1.5)
	if code_save_maximum_timer.time_left <= 0:
		print_debug("Saving...")
		code_save_maximum_timer.start(5)

func code_save_maximum_timeout() -> void:
	code_save_deferred_timer.stop()
	code_save()

func code_save() -> void:
	code_save_maximum_timer.stop()
	if editor.text == "": return
	
	var level_index := SaveManager.current_level
	if level_index not in SaveManager.level_save_data:
		SaveManager.level_save_data[level_index] = LevelSaveData.new()
		SaveManager.level_save_data[level_index].level_id = level_index
	
	SaveManager.level_save_data[level_index].previous_code = controls.sanitize_output(editor.text)
	SaveManager.write_save_data()
	print_debug("Saved!")

func update_enemies(start, goal):
	if level_node == null: return
	var enemies = get_tree().get_nodes_in_group("race")
	for e in enemies:
		e._on_player_move(start, goal)
