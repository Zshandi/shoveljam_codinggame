extends CanvasLayer

@export
var context:Node = null

var expression = Expression.new()

const execution_min_time_ms := 350

const KEYWORD_COLOUR = Color(0xff7085ff)
const CONTROL_FLOW_KEYWORD_COLOUR = Color(0xff8cccff)
const MEMBER_KEYWORD_COLOUR = Color(0xbce0ffff)

func _ready():
	%Editor.grab_focus()
	#sdsds
	for x in [%Editor,%Variables, %Docs]:
		x.syntax_highlighter.function_color = Color(0x57b3ffff)
		x.syntax_highlighter.number_color = Color(0xa1ffe0ff)
		x.syntax_highlighter.member_variable_color = Color(0xbce0ffff)
		x.syntax_highlighter.symbol_color = Color(0xabc9ffff)
		
		x.syntax_highlighter.add_color_region("\"","\"",Color(0xffeda1ff),false)
		x.syntax_highlighter.add_color_region("#","",Color(0xcdcfd280),true)
		x.syntax_highlighter.add_color_region("!!","",Color(0xff786bff),true)
		x.syntax_highlighter.add_color_region("**","",Color(0x42ffc2ff),true)
		
		x.syntax_highlighter.add_keyword_color("var",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("true",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("false",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("in",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("func",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("class",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("enum",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("const",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("await",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("and",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("or",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("not",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("null",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("self",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("ERROR",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("is",KEYWORD_COLOUR)
		
		x.syntax_highlighter.add_keyword_color("for",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("if",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("elif",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("else",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("return",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("break",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("continue",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("pass",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("while",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("repeat",CONTROL_FLOW_KEYWORD_COLOUR)

func _input(event: InputEvent) -> void:
	if event.is_action("Go_Keyboard") and event.is_pressed():
		if %GO.visible:
			_on_go_pressed()
		else:
			_on_reset_pressed()
		
		get_viewport().set_input_as_handled()

func _on_go_pressed() -> void:
	
	%Reset.show()
	%GO.hide()
	
	await execute_block(0, 0)
	
	if context.dead:
		%Editor.text += "\n!!ERROR: You crashed"
	else:
		%Editor.text += "\n# Execution complete!"
	update_var_display()

func _on_reset_pressed():
	LevelManager.load_current()
	reset_output()
	%Editor.show()
	
	%Reset.hide()
	%GO.show()

func set_output(line_num:int, output:Variant):
	var line:String = %Editor.get_line(line_num)
	const output_prefix = " # result: "
	line = line.split(output_prefix, true, 1)[0]
	if output != null:
		line = line + output_prefix + str(output)
		print_debug("result for line ", line_num, ": ", output)
	%Editor.set_line(line_num, line)

var has_error := false

func output_result(line_num:int, result:ExecutionResult) -> void:
	if result.status == ResultStatus.Completed:
		set_output(line_num, result.value_str)
	elif result.status == ResultStatus.Failed:
		context.trigger_death()
		set_output(line_num, "!!ERROR: " + result.value_str)
		%Editor.text += "\n!!ERROR: " + result.value_str
		has_error = true

func reset_output():
	var line_num = 0
	while line_num < %Editor.get_line_count():
		set_output(line_num, null)
		if %Editor.get_line(line_num).begins_with("!!ERROR") or %Editor.get_line(line_num) == "# Execution complete!":
			%Editor.remove_line_at(line_num)
		else:
			line_num += 1
	has_error = false

func skip_block(line_num:int, until_indent_level:int) -> int:
	while  line_num < %Editor.get_line_count():
		var line = %Editor.get_line(line_num)
		var current_indent = 0
		for character in line:
			if character == "\t": #TODO: Allow spaces
				current_indent = current_indent + 1
			else:
				break
		
		if current_indent <= until_indent_level:
			break
		
		line_num += 1
		
		set_output(line_num, null)
	
	return line_num

func execute_block(line_num:int, expected_indent_level:int, is_loop:bool = false) -> int:
	
	var was_if := false
	var was_if_consumed := false
	
	while  line_num < %Editor.get_line_count():
		var line = %Editor.get_line(line_num)
		
		var stripped_line = line.split("#", true, 1)[0].strip_edges()
		
		## Pre-checks BEGIN ##
		
		# Get indentation
		var current_indent = 0
		for character in line:
			if character == "\t": #TODO: Allow spaces
				current_indent = current_indent + 1
			else:
				break
		
		# Check indentation
		if current_indent > expected_indent_level:
			var result = ExecutionResult.new("Unexpected indentation", ResultStatus.Failed)
			output_result(line_num, result)
			return %Editor.get_line_count()
		elif current_indent < expected_indent_level:
			break
		
		# Ignore empty
		if stripped_line == "":
			# ignore empty lines
			line_num += 1
			was_if = false
			was_if_consumed = false
			continue
		
		## Pre-checks END ##
		
		## Check for if/elif/else BEGIN ##
		
		# Check for if
		var if_regex := RegEx.new()
		if_regex.compile("^if (.*):")
		var if_regex_result := if_regex.search(stripped_line)
		
		if if_regex_result == null:
			# No if found, so check for elif
			var elif_regex := RegEx.new()
			elif_regex.compile("^elif (.*):")
			var elif_regex_result = elif_regex.search(stripped_line)
			if elif_regex_result != null and not was_if:
				var result = ExecutionResult.new("Unexpected elif (needs an if)", ResultStatus.Failed)
				output_result(line_num, result)
				return %Editor.get_line_count()
			else:
				if_regex_result = elif_regex_result
		
		if if_regex_result != null:
			
			was_if = true
			if was_if_consumed:
				line_num = skip_block(line_num + 1, expected_indent_level)
				continue
			
			var condition = if_regex_result.get_string(1)
			var condition_result = await execute_expression(condition)
			
			output_result(line_num, condition_result)
			
			if context.dead or condition_result.status == ResultStatus.Failed:
				return %Editor.get_line_count()
			
			if condition_result.value == true:
				line_num = await execute_block(line_num + 1, expected_indent_level + 1, is_loop)
				if is_loop and line_num == -1: return -1
				# If gets consumed once it's true, which means no further ifs will be evaluated
				was_if_consumed = true
			else:
				line_num = skip_block(line_num + 1, expected_indent_level)
			
			continue
		
		# no if or elif, so check for else
		var else_regex := RegEx.new()
		else_regex.compile("^else:")
		var else_regex_result := else_regex.search(stripped_line)
		if else_regex_result != null:
			if not was_if:
				var result = ExecutionResult.new("Unexpected else (needs an if)", ResultStatus.Failed)
				output_result(line_num, result)
				return %Editor.get_line_count()
			
			if was_if_consumed:
				line_num = skip_block(line_num + 1, expected_indent_level)
			else:
				line_num = await execute_block(line_num + 1, expected_indent_level + 1, is_loop)
				if is_loop and line_num == -1: return -1
			was_if = false
			continue
		
		was_if = false
		was_if_consumed = false
		
		## Check for if/elif/else END ##
		
		## Repeat loop BEGIN ##
		
		var repeat_regex := RegEx.new()
		repeat_regex.compile("^repeat (.*):")
		var repeat_regex_result := repeat_regex.search(stripped_line)
		if repeat_regex_result != null:
			var condition = repeat_regex_result.get_string(1)
			var condition_result = await execute_expression(condition)
			
			output_result(line_num, condition_result)
			
			var line_num_prev = line_num
			for i in range(condition_result.value):
				line_num = await execute_block(line_num_prev + 1, expected_indent_level + 1)
				if has_error:
					return %Editor.get_line_count()
			
			continue
		
		## Repeat loop END ##
		
		## Finally, just evaluate the single line
		
		var result := await execute_line(stripped_line)
		output_result(line_num, result)
		
		if context.dead or result.status == ResultStatus.Failed:
			return %Editor.get_line_count()
		
		line_num += 1
	
	return line_num

func execute_line(line:String) -> ExecutionResult:
	var equals_regex = RegEx.new()
	equals_regex.compile("[^=!><]=[^=!><]")
	
	if equals_regex.search(line) != null:
		var sides = line.split("=", true, 1)
		if len(sides) >= 2:
			var left_hand_side = sides[0].strip_edges()
			var variable_value = sides[1].strip_edges()
			var var_name = left_hand_side
			
			if left_hand_side.begins_with("var "): #TODO: allow tab
				var_name = left_hand_side.substr(4).strip_edges()
				if var_name in context.user_variables:
					# This is to account for dictionary assignment also adding the value
					return ExecutionResult.new("re-define variable", ResultStatus.Failed)
			else:
				if !(var_name in context.user_variables):
					# This is to account for dictionary assignment also adding the value
					return ExecutionResult.new("assignment to undefined variable", ResultStatus.Failed)
			
			var evaluated_value = await execute_expression(variable_value)
			
			if evaluated_value.status == ResultStatus.Completed:
				context.user_variables[var_name] = evaluated_value.value
				%Editor.syntax_highlighter.add_member_keyword_color(var_name,MEMBER_KEYWORD_COLOUR)
				return evaluated_value
			else:
				return evaluated_value
		else:
			return ExecutionResult.new("invalid assign", ResultStatus.Failed)
	elif line.begins_with("var "):
		var var_name = line.substr(4).strip_edges()
		if var_name in context.user_variables:
			# This is to account for dictionary assignment also adding the value
			return ExecutionResult.new("re-define variable", ResultStatus.Failed)
		context.user_variables[var_name] = null
		return ExecutionResult.new("(variable defined with no value)", ResultStatus.Completed)
	
	print("final line: ", line)
	return await execute_expression(line)

func replace_vars_with_dictionaries(expr:String) -> String:
	# TODO: There's a better way to do this...
	for var_name in context.user_variables.keys():
		var regex = RegEx.new()
		regex.compile("\\b" + var_name + "\\b")
		expr = regex.sub(expr, "user_variables[\""+var_name+"\"]", true)
	
	return expr

func wait_for_ticks(ticks_ms:int) -> void:
	var ms_remaining := ticks_ms - Time.get_ticks_msec()
	var seconds_remaining := ms_remaining / 1000.0
	await get_tree().create_timer(seconds_remaining).timeout

func execute_expression(expr:String) -> ExecutionResult:
	
	var end_ticks = Time.get_ticks_msec() + execution_min_time_ms
	expr = replace_vars_with_dictionaries(expr)
	
	var error = expression.parse(expr, ["DisplayServer"])
	if error != OK:
		return ExecutionResult.new("Parse error: " + expression.get_error_text(), ResultStatus.Failed)
	var result = await expression.execute([DisplayServer], context)
	if not expression.has_execute_failed():
		await wait_for_ticks(end_ticks)
		return ExecutionResult.new(result)
	# something failed
	await wait_for_ticks(end_ticks)
	return ExecutionResult.new(expression.get_error_text(), ResultStatus.Failed)
	
func update_var_display() -> void:
	%Variables.text = ""
	for variable in context.user_variables:
		%Variables.text += "%s: %s\n" % [variable, str(context.user_variables[variable])]

enum ResultStatus {
	Completed,
	Failed,
	Skipped
}

class ExecutionResult:
	extends RefCounted
	
	func _init(value_p:Variant, status_p:ResultStatus = ResultStatus.Completed) -> void:
		status = status_p
		value = value_p
		if value == null:
			if status == ResultStatus.Completed:
				value_str = "(Completed, no result)"
			elif status == ResultStatus.Failed:
				value_str = "Unknown error"
			else:
				value_str = "Skipped"
		else:
			value_str = str(value)
	
	var status:ResultStatus
	var value:Variant
	var value_str:String
