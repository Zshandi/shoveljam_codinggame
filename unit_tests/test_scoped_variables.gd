extends Node

func test_top_level_assign_no_declare() -> void:
	var sv := ScopedVariables.new()
	assert(sv.can_assign("hello", "world") == false)
	assert(sv.assign("hello", "world") == false)

func test_top_level_declare_and_assign() -> void:
	var sv := ScopedVariables.new()
	assert(sv.can_declare("hello") == true)
	assert(sv.has_var("hello") == false)
	assert(sv.declare("hello") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == null)
	
	assert(sv.can_assign("hello", "world") == true)
	assert(sv.assign("hello", "world") == true)
	assert(sv.get_var("hello") == "world")
	
	assert(sv.assign("hello", "you") == true)
	assert(sv.get_var("hello") == "you")
	assert(sv.has_var("hello") == true)

func test_first_level_declare_and_assign() -> void:
	var sv := ScopedVariables.new()
	sv.increase_scope()
	assert(sv.can_declare("hello") == true)
	assert(sv.has_var("hello") == false)
	assert(sv.declare("hello") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == null)
	
	assert(sv.can_assign("hello", "world") == true)
	assert(sv.assign("hello", "world") == true)
	assert(sv.get_var("hello") == "world")
	
	assert(sv.assign("hello", "you") == true)
	assert(sv.get_var("hello") == "you")
	assert(sv.has_var("hello") == true)

func test_top_level_declare_first_level_assign() -> void:
	var sv := ScopedVariables.new()
	assert(sv.can_declare("hello") == true)
	assert(sv.has_var("hello") == false)
	assert(sv.declare("hello") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == null)
	
	sv.increase_scope()
	
	assert(sv.can_assign("hello", "world") == true)
	assert(sv.assign("hello", "world") == true)
	assert(sv.get_var("hello") == "world")

func test_top_level_declare_first_level_shadow() -> void:
	var sv := ScopedVariables.new()
	assert(sv.can_declare("hello") == true)
	assert(sv.has_var("hello") == false)
	assert(sv.declare("hello") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == null)
	
	assert(sv.assign("hello", "world") == true)
	assert(sv.get_var("hello") == "world")
	
	sv.increase_scope()
	
	assert(sv.can_declare("hello") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.declare("hello") == true)
	assert(sv.get_var("hello") == null)
	
	assert(sv.assign("hello", "you") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == "you")
	
	sv.decrease_scope()
	
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == "world")

func test_looped_scope() -> void:
	var sv := ScopedVariables.new()
	sv.increase_scope()
	
	assert(sv.can_declare("i") == true)
	assert(sv.has_var("i") == false)
	
	# Loop 1
	sv.increase_scope()
	
	assert(sv.declare("i") == true)
	assert(sv.get_var("i") == null)
	
	assert(sv.assign("i", 1) == true)
	assert(sv.get_var("i") == 1)
	# Within loop re-assignment should be fine
	assert(sv.assign("i", 1) == true)
	assert(sv.get_var("i") == 1)
	
	# Shouldn't be able to re-declare in loop
	assert(sv.can_declare("i") == false)
	
	sv.decrease_scope()
	# Loop 2
	sv.increase_scope()
	
	assert(sv.declare("i") == true)
	assert(sv.get_var("i") == null)
	
	assert(sv.assign("i", 2) == true)
	assert(sv.get_var("i") == 2)
	
	sv.decrease_scope()
	# Loop 3
	sv.increase_scope()
	
	assert(sv.declare("i") == true)
	assert(sv.get_var("i") == null)
	
	assert(sv.assign("i", 3) == true)
	assert(sv.get_var("i") == 3)
	
	sv.decrease_scope()
	
	# Out of loop, loop var shouldn't exist
	assert(sv.has_var("i") == false)
	
	sv.decrease_scope()
	assert(sv.has_var("i") == false)

func test_top_level_decrease_scope() -> void:
	var sv := ScopedVariables.new()
	sv.decrease_scope()
	assert(sv.has_var("hello") == false)
	
	assert(sv.declare("hello") == true)
	assert(sv.has_var("hello") == true)
	assert(sv.get_var("hello") == null)
	
	sv.decrease_scope()
	assert(sv.has_var("hello") == false)
	
	sv.decrease_scope()
	assert(sv.has_var("hello") == false)

func run_tests() -> void:
	print("Starting tests...")
	for method in get_method_list():
		var name:String = method["name"]
		if not name.begins_with("test_"): continue
		
		print("Running ", name)
		call(name)
	
	print("All tests passed!")

func _ready() -> void:
	run_tests()
