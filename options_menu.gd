extends MarginContainer

func _ready() -> void:
	Options.load_settings()
	%MusicVolumeSlider.set_value_no_signal(Options.music_volume)
	%SoundVolumeSlider.set_value_no_signal(Options.sound_volume)
	%ExecutionSpeedSlider.set_value_no_signal(Options.code_execution_speed)
	%TypingSoundButton.set_pressed_no_signal(Options.typing_sound_enabled)
	%FullScreenButton.set_pressed_no_signal(Options.is_full_screen)


func _on_typing_sound_button_toggled(toggled_on: bool) -> void:
	Options.typing_sound_enabled = toggled_on
	Options.save_settings()


func _on_full_screen_button_toggled(toggled_on: bool) -> void:
	Options.is_full_screen = toggled_on
	Options.save_settings()


func _on_sound_volume_slider_value_changed(value: float) -> void:
	Options.sound_volume = value
	Options.save_settings()


func _on_music_volume_slider_value_changed(value: float) -> void:
	Options.music_volume = value
	Options.save_settings()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_execution_speed_slider_value_changed(value: float) -> void:
	Options.code_execution_speed = int(value)
	Options.save_settings()
