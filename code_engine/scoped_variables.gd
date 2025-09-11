extends RefCounted
class_name ScopedVariables

var scope_stack:Array[Dictionary] = [{}]

var top_scope:Dictionary:
	get: return scope_stack[-1] if scope_stack.size() > 0 else null

var current_scope:Dictionary = {}

func evaluate_current_scope():
	current_scope = {}
	for scope in scope_stack:
		for key in scope.keys():
			current_scope[key] = scope[key]

func can_declare(name:String) -> bool:
	# Should include check with warning if shadowing variables in outer scope
	return not top_scope.has(name)

func declare(name:String) -> bool:
	if can_declare(name):
		top_scope[name] = null
		current_scope[name] = null
		return true
	else:
		return false

func has_var(name:String) -> bool:
	return current_scope.has(name)

func get_var(name:String) -> Variant:
	return current_scope[name] if has_var(name) else null

func can_assign(name:String, value:Variant) -> bool:
	# May add to this to include check if var is const
	return has_var(name)

func assign(name:String, value:Variant) -> bool:
	if not has_var(name): return false
	for i in range(-1, -scope_stack.size()-1, -1):
		var scope = scope_stack[i]
		if scope.has(name):
			scope[name] = value
			current_scope[name] = value
			return true
	assert(false, "has_var() was true, but key never found")
	return false

func increase_scope() -> void:
	scope_stack.push_back({})

func decrease_scope() -> void:
	if scope_stack.size() > 1:
		scope_stack.pop_back()
	else:
		assert(false, "decreased to 0 scope, which probably shouldn't happen")
		scope_stack = [{}]
	evaluate_current_scope()
