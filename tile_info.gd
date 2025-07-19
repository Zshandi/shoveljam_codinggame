extends RefCounted
class_name TileInfo

var type:TileType
var name:String

func _init(p_type:TileType, p_name:String = ""):
	type = p_type
	name = p_name

func _to_string() -> String:
	var result = "TileInfo{type = TileInfo.TileType." + TileType.keys()[type]
	if name != "":
		result += ", name = \"" + name + "\""
	result += "}"
	return result

enum TileType {
	EMPTY,
	WALL,
	ENEMY,
	FLOPPY,
	ITEM
}
