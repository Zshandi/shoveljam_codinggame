extends CodeEdit

var text_before_regex := RegEx.new()

var pre_direction_regex := RegEx.new()
var pre_direction_val_regex := RegEx.new()

var pre_display_server_negative_regex := RegEx.new()
var pre_window_set_mode_regex := RegEx.new()
var pre_window_set_mode_negative_regex := RegEx.new()
var pre_window_mode_regex := RegEx.new()
var pre_window_mode_regex2 := RegEx.new()

var pre_move_negative_regex := RegEx.new()

var pre_get_tree_negative_regex := RegEx.new()
var pre_quit_regex := RegEx.new()

func _ready() -> void:
	code_completion_prefixes = [".", "(", "= "]
	
	# Matches all non-whitespace characters immediately preceding the caret (0xFFFF)
	text_before_regex.compile("\\s?(\\S*)\uFFFF")
	
	# This only matches strings that contain move or quotes
	pre_move_negative_regex.compile("(move|\"|\\.$)")
	# This only matches strings that contain get_tree or quotes
	pre_get_tree_negative_regex.compile("(get_tree|\"|\\.$)")
	pre_quit_regex.compile("[^\\.a-zA-Z_]?get_tree\\(\\)\\.[a-z_]*$")
	
	
	# This matches strings that end with move(Something
	pre_direction_regex.compile("[^\\.a-zA-Z_]?move\\([a-zA-Z]*$")
	# This matches strings that end with Direction.SOMETHING
	pre_direction_val_regex.compile("[^\\.a-zA-Z_]?Direction\\.[A-Z]*$")
	
	pre_display_server_negative_regex.compile("(DisplayServer|\"|\\.$)")
	pre_window_set_mode_regex.compile("[^\\.a-zA-Z_]?DisplayServer\\.[A-Z]*$")
	pre_window_set_mode_negative_regex.compile("(window_set_mode|\")")
	pre_window_mode_regex.compile("[^\\.a-zA-Z_]?DisplayServer\\.window_set_mode\\([a-zA-Z]*$")
	pre_window_mode_regex.compile("[^\\.a-zA-Z_]?DisplayServer\\.window_set_mode\\(DisplayServer\\.[A-Z]*$")

func _request_code_completion(force: bool) -> void:
	add_code_completions()
	update_code_completion_options(force)

func add_code_completions():
	var text_complete = get_text_for_code_completion()
	
	var regex_match = text_before_regex.search(text_complete)
	var text_before_complete = ""
	if regex_match != null: text_before_complete = regex_match.get_string(1)
	
	if not pre_display_server_negative_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_CLASS, "DisplayServer", "DisplayServer.")
	elif pre_window_set_mode_regex.search(text_before_complete) and not pre_window_set_mode_negative_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "window_set_mode", "window_set_mode(")
		return
	elif pre_window_mode_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_ENUM, "DisplayServer.WINDOW_MODE_FULLSCREEN", "DisplayServer.WINDOW_MODE_FULLSCREEN")
		add_code_completion_option(CodeEdit.KIND_ENUM, "DisplayServer.WINDOW_MODE_WINDOWED", "DisplayServer.WINDOW_MODE_WINDOWED")
		return
	elif pre_window_mode_regex2.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_ENUM, "WINDOW_MODE_FULLSCREEN", "WINDOW_MODE_FULLSCREEN")
		add_code_completion_option(CodeEdit.KIND_ENUM, "WINDOW_MODE_WINDOWED", "WINDOW_MODE_WINDOWED")
		return
	
	if pre_direction_val_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_ENUM, "RIGHT", "RIGHT")
		add_code_completion_option(CodeEdit.KIND_ENUM, "LEFT", "LEFT")
		add_code_completion_option(CodeEdit.KIND_ENUM, "UP", "UP")
		add_code_completion_option(CodeEdit.KIND_ENUM, "DOWN", "DOWN")
		return
	elif pre_direction_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_ENUM, "Direction", "Direction.")
		return
	
	if not pre_get_tree_negative_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "get_tree", "get_tree()")
	elif pre_quit_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "quit", "quit()")
		return
	
	if not pre_move_negative_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "move", "move(")

func _on_text_changed() -> void:
	_request_code_completion(true)
