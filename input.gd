extends CodeEdit

func _ready() -> void:
	code_completion_prefixes = [".", "(", "= "]

func _request_code_completion(force: bool) -> void:
	var text_complete = get_text_for_code_completion()
	var text_before_regex = RegEx.new()
	text_before_regex.compile("\\s?(\\S*)\uFFFF")
	
	var regex_match = text_before_regex.search(text_complete)
	var text_before_complete = ""
	if regex_match != null: text_before_complete = regex_match.get_string(1)
	
	if not text_before_complete.contains("move"):
		add_code_completion_option(CodeEdit.KIND_FUNCTION, "move", "move(")
	
	if text_before_complete.contains("Direction."):
		add_code_completion_option(CodeEdit.KIND_ENUM, "RIGHT", "RIGHT")
		add_code_completion_option(CodeEdit.KIND_ENUM, "LEFT", "LEFT")
		add_code_completion_option(CodeEdit.KIND_ENUM, "UP", "UP")
		add_code_completion_option(CodeEdit.KIND_ENUM, "DOWN", "DOWN")
	elif text_before_complete.contains("move("):
		add_code_completion_option(CodeEdit.KIND_ENUM, "Direction", "Direction.")
	
	update_code_completion_options(force)

func _on_text_changed() -> void:
	_request_code_completion(true)
