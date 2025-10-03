extends Object
class_name Serializer

const _CLASS_NAME_KEY = "__serialized_class_name__"

static func is_scripted_object(obj: Variant) -> bool:
	return \
	obj is Object && \
	obj.get_script() != null && \
	obj.get_script().get_global_name() != ""

static func serialize_object(obj: Variant) -> Variant:
	if is_scripted_object(obj):
		return serialize_scripted_object(obj)
	
	elif obj is Array:
		return obj.map(func(elem):
			return serialize_object(elem)
		)
	
	elif obj is Dictionary:
		for key in obj.keys():
			obj[key] = serialize_object(obj[key])
		return obj

	else:
		return obj


static func serialize_scripted_object(obj: Variant) -> Variant:
	assert(is_scripted_object(obj))
	var result := {}
	result[_CLASS_NAME_KEY] = obj.get_script().get_global_name()
	for property_dict in obj.get_property_list():
		if property_dict["usage"] & PROPERTY_USAGE_STORAGE:
			var prop_name = property_dict["name"]
			if prop_name == "script": continue
			print_debug("storing property: ", prop_name)

			var value = serialize_object(obj.get(prop_name))
			result[prop_name] = value

	return result

static func deserialize_object(obj: Variant) -> Variant:
	if obj is Array:
		return obj.map(func(elem):
			return deserialize_object(elem)
		)
	
	elif obj is Dictionary:
		if _CLASS_NAME_KEY in obj:
			var _class_name = obj[_CLASS_NAME_KEY]
			for class_dict in ProjectSettings.get_global_class_list():
				if class_dict["class"] != _class_name:
					continue
				
				var script = load(class_dict["path"])
				if script is Script and script.can_instantiate():
					var instance = script.new()

					deserialize_scripted_object(instance, obj)
					return instance
				else:
					assert(false, "Failed to load class " + _class_name + ": could not instantiate")
				
				break
			assert(false, "Failed to load class " + _class_name + ": could not find class script")
		

		for key in obj.keys():
			obj[key] = deserialize_object(obj[key])
		return obj

	else:
		return obj

static func deserialize_scripted_object(obj_instance: Variant, value_dictionary: Variant) -> bool:
	if !(value_dictionary is Dictionary and _CLASS_NAME_KEY in value_dictionary):
		return false
	
	var _class_name = value_dictionary[_CLASS_NAME_KEY]
	if _class_name != obj_instance.get_script().get_global_name():
		return false
		
	for property_dict in obj_instance.get_property_list():
		if property_dict["usage"] & PROPERTY_USAGE_STORAGE:
			var prop_name = property_dict["name"]
			if prop_name == "script": continue
			print_debug("loading property: ", prop_name)

			if not prop_name in value_dictionary:
				print_debug("WARNING: Failed to find property ", prop_name, " in serialized dictionary")
				break
			
			obj_instance.set(prop_name, deserialize_object(value_dictionary[prop_name]))
			
	
	return false
