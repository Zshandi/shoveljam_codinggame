extends CodeEdit
class_name CodeUnedit

var original_text: String
@export var is_editable := false
var edit_override = false

signal text_updated

func _ready() -> void:
	original_text = text
	text_changed.connect(self._on_text_changed)
	text_set.connect(self._on_text_set)
	context_menu_enabled = false
	
func add_text(new_text:String) -> void:
	edit_override = true
	text += new_text
	await text_updated
	edit_override = false
	
func set_line_text(line_num:int, new_text:String) -> void:
	edit_override = true
	set_line(line_num, new_text)
	await text_updated
	edit_override = false
	

func _on_text_changed() -> void:
	if not is_editable and not edit_override:
		var caret_column = get_caret_column()
		var caret_line = get_caret_line()
		caret_column -= len(text)-len(original_text)
		text = original_text
		set_caret_column(caret_column)
		set_caret_line(caret_line)
	else:
		original_text = text
	text_updated.emit()

func _on_text_set():
	original_text = text
