@tool
extends Resource
class_name LevelInfo

func _to_string():
    return

@export
var name: String:
    set(value):
        name = value
        update_resource_name()
        

@export_multiline
var description: String

@export
var scene: PackedScene:
    set(value):
        scene = value
        update_resource_name()

func update_resource_name():
    if Engine.is_editor_hint():
        var scene_name := scene.resource_path.split("/")[-1] if scene != null else "NULL"
        resource_name = "(" + name + ", " + scene_name + ")"