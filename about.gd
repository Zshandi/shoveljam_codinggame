extends CodeUnedit

func _ready() -> void:
	var version = ProjectSettings.get_setting("application/config/version")
	text = text.replace("[version]", version)
