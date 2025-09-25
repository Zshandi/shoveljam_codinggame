extends Resource
class_name LevelSaveData

var level_id: int

var level_completed: bool

var previous_code: String

func to_save_data() -> Variant:
	var save_dict := \
	{
		"level_id": level_id,
		"level_completed": level_completed,
		"previous_code": previous_code,
	}
	return save_dict

static func from_save_data(data: Variant) -> LevelSaveData:
	var save_dict: Dictionary = data

	var result := LevelSaveData.new()
	result.level_id = save_dict["level_id"]
	result.level_completed = save_dict["level_completed"]
	result.previous_code = save_dict["previous_code"]

	return result