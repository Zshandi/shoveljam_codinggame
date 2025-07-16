extends CodeEdit

var original_text

func _ready() -> void:
	original_text = text

func _on_text_changed() -> void:
	text = original_text
