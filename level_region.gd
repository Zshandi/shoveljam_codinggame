extends MarginContainer

signal mouse_pressed
signal mouse_released
signal mouse_wheel_up
signal mouse_wheel_down

var is_mouse_over = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_mouse_over: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				mouse_pressed.emit()
			elif event.is_released():
				mouse_released.emit()
	
	if event.is_action("Mouse_Wheel_Up") and event.is_released():
		mouse_wheel_up.emit()
	elif event.is_action("Mouse_Wheel_Down") and event.is_released():
		mouse_wheel_down.emit()

func _on_mouse_entered() -> void:
	is_mouse_over = true

func _on_mouse_exited() -> void:
	is_mouse_over = false
