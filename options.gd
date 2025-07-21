extends Node

var music_volume:float:
	get:
		var index = AudioServer.get_bus_index(&"Music")
		return db_to_linear(AudioServer.get_bus_volume_db(index))
	set(value):
		var index = AudioServer.get_bus_index(&"Music")
		AudioServer.set_bus_volume_db(index, linear_to_db(value))

var sound_volume:float:
	get:
		var index = AudioServer.get_bus_index(&"Sound")
		return db_to_linear(AudioServer.get_bus_volume_db(index))
	set(value):
		var index = AudioServer.get_bus_index(&"Sound")
		AudioServer.set_bus_volume_db(index, linear_to_db(value))

var last_windowed_mode := DisplayServer.WINDOW_MODE_WINDOWED

var is_full_screen:bool:
	get:
		return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	set(value):
		if value == is_full_screen: return
		if (value):
			last_windowed_mode = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(last_windowed_mode)

var typing_sound_enabled:bool = true

const min_code_exec_time_ms_default := 650
var min_code_exec_time_ms:int = min_code_exec_time_ms_default

var code_execution_speed:int:
	get:
		return clampi(min_code_exec_time_ms / min_code_exec_time_ms_default, 0, 2)
	set(value):
		min_code_exec_time_ms = min_code_exec_time_ms_default * clamp(value, 0, 2)

func save_settings() -> void:
	var save_dict := {}
	save_dict["music_volume"] = music_volume
	save_dict["sound_volume"] = sound_volume
	save_dict["is_full_screen"] = is_full_screen
	save_dict["typing_sound_enabled"] = typing_sound_enabled
	save_dict["code_execution_speed"] = code_execution_speed
	
	var save_file := FileAccess.open("user://settings", FileAccess.WRITE)
	save_file.store_var(save_dict)
	save_file.close()

func load_settings() -> void:
	if !FileAccess.file_exists("user://settings"):
		# If no settings have been saved, leave values as default
		print_debug("Loading default settings...")
		return
	
	var save_file := FileAccess.open("user://settings", FileAccess.READ)
	var save_dict:Dictionary = save_file.get_var()
	
	music_volume = save_dict["music_volume"]
	sound_volume = save_dict["sound_volume"]
	is_full_screen = save_dict["is_full_screen"]
	typing_sound_enabled = save_dict["typing_sound_enabled"]
	if "code_execution_speed" in save_dict:
		code_execution_speed = save_dict["code_execution_speed"]

func _ready() -> void:
	load_settings()
