extends CodeUnedit

var text_before_regex := RegEx.new()
var line_before_regex := RegEx.new()

var pre_direction_regex := RegEx.new()
var pre_direction_val_regex := RegEx.new()

var pre_display_server_negative_regex := RegEx.new()
var pre_window_set_mode_regex := RegEx.new()
var pre_window_set_mode_negative_regex := RegEx.new()
var pre_window_mode_regex := RegEx.new()
var pre_window_mode_regex2 := RegEx.new()

var pre_move_negative_regex := RegEx.new()
var pre_check_move_negative_regex := RegEx.new()

var pre_get_tree_negative_regex := RegEx.new()
var pre_quit_regex := RegEx.new()

var pre_global_func_regex := RegEx.new()

func _ready() -> void:
	super()
	is_editable = true
	context_menu_enabled = true
	code_completion_prefixes = [".", "(", "= "]
	
	# Matches all non-whitespace characters immediately preceding the caret (0xFFFF)
	text_before_regex.compile("\\s?(\\S*)\uFFFF")
	
	line_before_regex.compile("([^\n]*)\uFFFF")
	
	# This only matches strings that contain move or quotes
	pre_move_negative_regex.compile("(move|\"|\\.$)")
	pre_check_move_negative_regex.compile("(check_move|\"|\\.$)")
	# This only matches strings that contain get_tree or quotes
	pre_get_tree_negative_regex.compile("(get_tree|\"|\\.$)")
	pre_quit_regex.compile("[^\\.a-zA-Z_]?get_tree\\(\\)\\.[a-z_]*$")
	
	
	# This matches strings that end with move(Something
	pre_direction_regex.compile("[^\\.a-zA-Z_]?(move|check_move)\\([a-zA-Z]*$")
	# This matches strings that end with Direction.SOMETHING
	pre_direction_val_regex.compile("[^\\.a-zA-Z_]?Direction\\.[A-Z]*$")
	
	pre_display_server_negative_regex.compile("(DisplayServer|\"|\\.$)")
	pre_window_set_mode_regex.compile("[^\\.a-zA-Z_]?DisplayServer\\.[A-Z]*$")
	pre_window_set_mode_negative_regex.compile("(window_set_mode|\")")
	pre_window_mode_regex.compile("[^\\.a-zA-Z_]?DisplayServer\\.window_set_mode\\([a-zA-Z]*$")
	pre_window_mode_regex2.compile("[^\\.a-zA-Z_]?DisplayServer\\.window_set_mode\\(DisplayServer\\.[A-Z]*$")
	
	pre_global_func_regex.compile("^[a-zA-Z_]*$")

func _request_code_completion(force: bool) -> void:
	add_code_completions()
	update_code_completion_options(force)

func add_code_completions():
	var text_complete = get_text_for_code_completion()
	
	var regex_match = text_before_regex.search(text_complete)
	var text_before_complete = ""
	if regex_match != null: text_before_complete = regex_match.get_string(1)
	
	regex_match = line_before_regex.search_all(text_complete)
	if len(regex_match) != 0:
		var line:String = regex_match[-1].get_string(1)
		if line.contains("#"):
			# No auto-complete for comments
			return
		var quote_regex = RegEx.new()
		quote_regex.compile("[^\\]\"")
		var quote_matches = quote_regex.search_all(line)
		if len(quote_matches) % 2 == 1:
			# No auto-complete inside string quotes
			return
	
	if not pre_display_server_negative_regex.search(text_before_complete) and pre_global_func_regex.search(text_before_complete):
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
	
	if not pre_get_tree_negative_regex.search(text_before_complete) and pre_global_func_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "get_tree", "get_tree()")
	elif pre_quit_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "quit", "quit()")
		return
	
	if not pre_move_negative_regex.search(text_before_complete) and pre_global_func_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "move", "move(")
	if not pre_check_move_negative_regex.search(text_before_complete) and pre_global_func_regex.search(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "check_move", "check_move(")
	
	#var last_of_text_regex = RegEx.new()
	#last_of_text_regex.compile("(^|[^a-zA-Z0-9_])([^a-zA-Z0-9_]*)")
	#var matches := last_of_text_regex.search_all(text_before_complete)
	#var last_text_before_complete = ""
	#if len(matches) != 0:
		#last_text_before_complete = matches[-1].get_string(1)
	#print_debug("last_text_before_complete: ", last_text_before_complete)
	if "TileInfo".begins_with(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "TileInfo", "TileInfo.")
	elif "TileInfo.TileType".begins_with(text_before_complete):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "TileType", "TileType.")
	else:
		add_enum_values(text_before_complete, "TileInfo.TileType", TileInfo.TileType)

func add_enum_values(value:String, enum_name:String, enum_type:Dictionary):
	for enum_key in enum_type.keys():
		var full_name = enum_name + "." + enum_key
		if full_name.begins_with(value):
			add_code_completion_option(CodeEdit.KIND_ENUM, enum_key, enum_key)
	return false

func _on_text_changed() -> void:
	super()
	if is_editable:
		if Options.typing_sound_enabled:
			%type1_sfx.play()
		_request_code_completion(true)
		
