extends CanvasLayer

@export
var context:Node = null

var expression = Expression.new()

func _on_go_pressed() -> void:
	var code = %Input.text
	
	var line_num := 1
	for line in code.split('\n'):
		print("executing line ", line_num, ": ")
		await execute_line(line)
		line_num = line_num + 1

func execute_line(line:String):
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
					print("ERROR: re-define variable")
					# TODO: OUTPUT ERROR
					return
			else:
				if !(var_name in context.user_variables):
					# This is to account for dictionary assignment also adding the value
					print("ERROR: assignment to undefined variable")
					# TODO: OUTPUT ERROR
					return
			
			line = "user_variables.set(\""+var_name+"\", "+variable_value+")"
		else:
			print("ERROR: invalid assign")
			# TODO: OUTPUT ERROR
			return
	else:
		line = replace_vars_with_dictionaries(line)
	
	print("final line: ", line)
	await execute_expression(line)

func replace_vars_with_dictionaries(expr:String) -> String:
	# TODO: Fix this to match against full word?
	for var_name in context.user_variables.keys():
		var regex = RegEx.new()
		regex.compile("\\b" + var_name + "\\b")
		expr = regex.sub(expr, "user_variables[\""+var_name+"\"]", true)
	
	return expr

func execute_expression(expr:String) -> void:
	var error = expression.parse(expr, ["DisplayServer"])
	if error != OK:
		# TODO: OUTPUT ERROR
		print(expression.get_error_text())
		#return null
	var result = await expression.execute([DisplayServer], context)
	if not expression.has_execute_failed():
		# TODO: do something with this??
		print("result: " + str(result))
