extends Camera2D

var tracking = false
var prev_mouse_position = Vector2.ZERO
var initial_mouse_position = Vector2.ZERO
var initial_camera_position = Vector2.ZERO

var min_zoom = 1.0
var max_zoom = 8.0
var zoom_level = 2.0

func _ready():
	zoom = Vector2(zoom_level,zoom_level)

func _process(delta):
	
	# drag the camera
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		tracking = false
	
	if tracking:
		global_position = initial_camera_position + (initial_mouse_position - Vector2(DisplayServer.mouse_get_position()))*(1.0/zoom_level)
		

func _on_level_region_mouse_pressed() -> void:
	tracking = true
	initial_mouse_position = Vector2(DisplayServer.mouse_get_position())
	initial_camera_position = global_position

func _on_level_region_mouse_released() -> void:
	tracking = false

func _on_level_region_mouse_wheel_down() -> void:
	zoom_level = clamp(zoom_level*0.9,min_zoom,max_zoom)
	zoom = Vector2(zoom_level,zoom_level)

func _on_level_region_mouse_wheel_up() -> void:
	zoom_level = clamp(zoom_level*1.1,min_zoom,max_zoom)
	zoom = Vector2(zoom_level,zoom_level)
