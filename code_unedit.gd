extends CodeEdit
class_name CodeUnedit

var original_text: String
@export var is_editable := false

func _ready() -> void:
	original_text = text
	text_changed.connect(self._on_text_changed)
	text_set.connect(self._on_text_set)
	context_menu_enabled = false

func _on_text_changed() -> void:
	if not is_editable:
		text = original_text
	else:
		original_text = text

func _on_text_set():
	original_text = text
