extends CodeEdit

var original_text

func _ready() -> void:
	original_text = text
	text_changed.connect(self._on_text_changed)
	context_menu_enabled = false

func _on_text_changed() -> void:
	text = original_text
