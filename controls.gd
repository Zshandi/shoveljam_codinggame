extends CanvasLayer

@export
var context:Node = null

var expression = Expression.new()

func _on_go_pressed() -> void:
	var code = %Input.text
	var result:Array
	var line_num := 1
	
	%Input.visible = false
	%Output.visible = true
	%Output.text = "Executing code:\n"
	
	for line in code.split('\n'):
		if line.strip_edges() == "":
			# ignore empty lines
			continue
		print("executing line ", line_num, ": ")
		result = await execute_line(line)
		if result[0]:
			%Output.text += "[color=green]%s: %s[/color]\n" % [line, result[1]]
		else:
			%Output.text += "[color=red]%s: ERROR %s[/color]\n" % [line, result[1]]
			break
		line_num = line_num + 1
	%Output.text += "Finished!\n"

func _on_reset_pressed():
	get_tree().reload_current_scene()

func execute_line(line:String) -> Array:
	line = line.strip_edges()
	if line.contains("="): # TODO Account for ==
		var sides = line.split("=")
		if len(sides) == 2:
			var left_hand_side = sides[0].strip_edges()
			var variable_value = replace_vars_with_dictionaries(sides[1].strip_edges())
			var var_name = left_hand_side
			
			if left_hand_side.begins_with("var "): #TODO: allow tab
				var_name = left_hand_side.substr(4).strip_edges()
				if var_name in context.user_variables:
					# This is to account for dictionary assignment also adding the value
					return [false, "re-define variable"]
			else:
				if !(var_name in context.user_variables):
					# This is to account for dictionary assignment also adding the value
					return [false, "assignment to undefined variable"]
			
			line = "user_variables.set(\""+var_name+"\", "+variable_value+")"
		else:
			return [false, "invalid assign"]
	else:
		line = replace_vars_with_dictionaries(line)
	
	print("final line: ", line)
	return await execute_expression(line)

func replace_vars_with_dictionaries(expr:String) -> String:
	# TODO: Fix this to match against full word?
	for var_name in context.user_variables.keys():
		var regex = RegEx.new()
		regex.compile("\\b" + var_name + "\\b")
		expr = regex.sub(expr, "user_variables[\""+var_name+"\"]", true)
	
	return expr

func execute_expression(expr:String) -> Array:
	var error = expression.parse(expr, ["DisplayServer"])
	if error != OK:
		print(expression.get_error_text())
		return [false, expression.get_error_text()]
	var result = await expression.execute([DisplayServer], context)
	if not expression.has_execute_failed():
		# TODO: do something with this??
		print("result: " + str(result))
		return [true, "Completed"]
	return [false, expression.get_error_text()]
