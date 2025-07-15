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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not tracking:
		tracking = true
		initial_mouse_position = Vector2(DisplayServer.mouse_get_position())
		initial_camera_position = global_position
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		tracking = false
	
	if tracking:
		global_position = initial_camera_position + (initial_mouse_position - Vector2(DisplayServer.mouse_get_position()))*(1.0/zoom_level)
		
	# zoom
	if Input.is_action_just_released("Mouse_Wheel_Up"):
		zoom_level = clamp(zoom_level*1.1,min_zoom,max_zoom)
		zoom = Vector2(zoom_level,zoom_level)
	elif Input.is_action_just_released("Mouse_Wheel_Down"):
		zoom_level = clamp(zoom_level*0.9,min_zoom,max_zoom)
		zoom = Vector2(zoom_level,zoom_level)
