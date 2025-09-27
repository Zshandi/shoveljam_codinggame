extends Node

var _current_version: String = ProjectSettings.get_setting("application/config/version")

var _save_data: Dictionary = {}

var level_save_data: Dictionary[int, LevelSaveData] = {}

var current_level: int = 0

func _ready() -> void:
	read_save_data()

func read_save_data() -> void:
	if !FileAccess.file_exists("user://save_data"):
		# If no save data found, this is a new save
		print_debug("New save created...")
		return
	
	var save_file := FileAccess.open("user://save_data", FileAccess.READ)
	_save_data = save_file.get_var()

	# This won't happen, but could once we up the version in the future
	var previous_version: String = _save_data["version"]
	if previous_version != _current_version:
		# In future, translate the save data if necessary, but
		#  for now assert false so we remember we need to translate it
		#assert(false, "Save data version invalid: must be " + _current_version)
		pass
	current_level = _save_data["current_level"]
	
	for key in _save_data["level_save_data"].keys():
		var value = _save_data["level_save_data"][key]
		print_debug("Saving level: ", value)
		level_save_data[key] = LevelSaveData.from_save_data(value)


func write_save_data() -> void:
	_save_data["version"] = _current_version
	_save_data["current_level"] = current_level
	
	_save_data["level_save_data"] = {}
	for key in level_save_data.keys():
		var data = level_save_data[key].to_save_data()
		print_debug("Saving level: ", data)
		_save_data["level_save_data"][key] = data

	var save_file := FileAccess.open("user://save_data", FileAccess.WRITE)
	save_file.store_var(_save_data, true)
	save_file.close()
