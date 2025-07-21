extends CanvasLayer

@export
var context:Node = null

var expression = Expression.new()

const execution_min_time_ms := 650

const KEYWORD_COLOUR = Color(0xff7085ff)
const CONTROL_FLOW_KEYWORD_COLOUR = Color(0xff8cccff)
const MEMBER_KEYWORD_COLOUR = Color(0xbce0ffff)


const keywords = [
	"var",
	"true",
	"false",
	"in",
	"func",
	"class",
	"enum",
	"is",
	"const",
	"await",
	"and",
	"or",
	"not",
	"null",
	"self"
]

const control_flow_keywords = [
	"for",
	"while",
	"repeat",
	"if",
	"elif",
	"else",
	"return",
	"pass",
	"break",
	"continue"
]

func _ready():
	%Editor.grab_focus()
	%TabContainer.set_tab_title(0,"Editor")
	add_syntax_highlighting()
	%Editor.show()

func add_syntax_highlighting():
	for x in [%Editor,%Variables, %Basics, %Movement, %Reacting, %About]:
		x.syntax_highlighter.function_color = Color(0x57b3ffff)
		x.syntax_highlighter.number_color = Color(0xa1ffe0ff)
		x.syntax_highlighter.member_variable_color = Color(0xbce0ffff)
		x.syntax_highlighter.symbol_color = Color(0xabc9ffff)
		
		x.syntax_highlighter.add_color_region("\"","\"",Color(0xffeda1ff),false)
		x.syntax_highlighter.add_color_region("#","",Color(0xcdcfd280),true)
		x.syntax_highlighter.add_color_region("!!","",Color(0xff786bff),true)
		x.syntax_highlighter.add_color_region("**","",Color(0x42ffc2ff),true)
		
		for k in keywords:
			x.syntax_highlighter.add_keyword_color(k,KEYWORD_COLOUR)
		for k in control_flow_keywords:
			x.syntax_highlighter.add_keyword_color(k,CONTROL_FLOW_KEYWORD_COLOUR)

func _input(event: InputEvent) -> void:
	if event.is_action("Go_Keyboard") and event.is_pressed():
		if %GO.visible:
			_on_go_pressed()
		else:
			_on_reset_pressed()
		
		get_viewport().set_input_as_handled()

var is_executing := false
var kill_execution := false
var starting_code : String
var has_error := false
signal execution_killed

func _on_go_pressed() -> void:
	has_error = false
	%Editor.show()
	%Reset.show()
	%GO.hide()
	%Editor.is_editable = false
	starting_code = %Editor.text
	is_executing = true
	await execute_block(0, 0)
	is_executing = false
	%Editor.set_line_as_executing(last_executed_line, false)
	if kill_execution:
		await get_tree().create_timer(0.01).timeout
		execution_killed.emit()
		return
	
	if context.dead:
		%Editor.add_text("\n!!ERROR: You crashed!")
		%crash_sfx.play()
	else:
		%Editor.add_text("\n** Execution completed without errors!")
		%beep_sfx.stop()
		%complete_sfx.play()
	%Editor.set_caret_line(%Editor.get_line_count())

func stop_execution():
	if is_executing:
		kill_execution = true
		%ExecutionTimer.stop()
		%ExecutionTimer.timeout.emit()
		await execution_killed
		kill_execution = false
	is_executing = false

func _on_reset_pressed():
	reset_state()
	LevelManager.load_current()

func reset_state():
	await stop_execution()
	reset_output()
	%Editor.show()
	%Editor.is_editable = true
	%Reset.hide()
	%GO.show()
	has_error = false

func set_output(line_num:int, output:Variant):
	if line_num >= %Editor.get_line_count():
		print_debug("line out of index", line_num, ": ", output)
	var line:String = %Editor.get_line(line_num)
	const output_prefix = " # result: "
	line = line.split(output_prefix, true, 1)[0]
	if output != null:
		line = line + output_prefix + str(output)
		print_debug("result for line ", line_num, ": ", output)
	%Editor.set_line_text(line_num, line)
	%Editor.set_line_as_center_visible(line_num)

func output_result(line_num:int, result:ExecutionResult) -> void:
	if result.status == ResultStatus.Completed:
		set_output(line_num, result.value_str)
		%beep_sfx.play()
	elif result.status == ResultStatus.Failed:
		context.trigger_death()
		set_output(line_num, "!!ERROR: " + result.value_str)
		%Editor.add_text("\n!!ERROR: " + result.value_str)
		has_error = true

func reset_output():
	%Editor.text = starting_code

func skip_block(line_num:int, until_indent_level:int, clear_output := true) -> int:
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
		
		if clear_output:
			set_output(line_num, null)
		
		line_num += 1
	
	return line_num

# Note: line_num is typically int, but can also be LoopControl, and returns int or LoopControl
func execute_block(line_num:Variant, expected_indent_level:int, is_loop:bool = false) -> Variant:
	
	var was_if := false
	var was_if_consumed := false
	
	while line_num < %Editor.get_line_count():
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
		if_regex.compile("^if[\\s\\(](.*):")
		var if_regex_result := if_regex.search(stripped_line)
		
		if if_regex_result == null:
			# No if found, so check for elif
			var elif_regex := RegEx.new()
			elif_regex.compile("^elif[\\s\\(](.*):")
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
			var condition_result = await execute_expression(condition, line_num)
			
			output_result(line_num, condition_result)
			
			if context.dead or condition_result.status == ResultStatus.Failed:
				return %Editor.get_line_count()
			
			if condition_result.value == true:
				line_num = await execute_block(line_num + 1, expected_indent_level + 1, is_loop)
				if line_num is LoopControl: return line_num
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
				if line_num is LoopControl: return line_num
			was_if = false
			continue
		
		was_if = false
		was_if_consumed = false
		
		## Check for if/elif/else END ##
		
		## Check for continue and break BEGIN ##
		
		if stripped_line == "continue":
			if is_loop:
				return LoopControl.CONTINUE
			else:
				var result = ExecutionResult.new("continue can only be used in a loop (repeat or while)", ResultStatus.Failed)
				output_result(line_num, result)
				return %Editor.get_line_count()
		
		if stripped_line == "break":
			if is_loop:
				return LoopControl.BREAK
			else:
				var result = ExecutionResult.new("break can only be used in a loop (repeat or while)", ResultStatus.Failed)
				output_result(line_num, result)
				return %Editor.get_line_count()
		
		## Check for continue and break END ##
		
		## Repeat loop BEGIN ##
		
		var repeat_regex := RegEx.new()
		repeat_regex.compile("^repeat[\\s\\(](.*):")
		var repeat_regex_result := repeat_regex.search(stripped_line)
		if repeat_regex_result != null:
			var count = repeat_regex_result.get_string(1)
			var count_result = await execute_expression(count, line_num)
			
			if context.dead or count_result.status == ResultStatus.Failed:
				output_result(line_num, count_result)
				return %Editor.get_line_count()
			
			if not (count_result.value is int):
				var result = ExecutionResult.new("repeat count must be a number, but instead got: " + count_result.value_str, ResultStatus.Failed)
				output_result(line_num, result)
				return %Editor.get_line_count()
			
			var line_num_prev = line_num
			for i in range(count_result.value):
				
				set_executing_line(line_num_prev)
				set_output(line_num_prev, "loop " + str(i+1) + " out of " + count_result.value_str)
				if i != 0:
					await get_tree().create_timer(execution_min_time_ms / 1000.0).timeout
				# This skip is just to clear the output
				skip_block(line_num_prev + 1, expected_indent_level, true)
				
				line_num = await execute_block(line_num_prev + 1, expected_indent_level + 1, true)
				if has_error:
					return %Editor.get_line_count()
				elif line_num is LoopControl:
					if line_num == LoopControl.BREAK:
						break
					# Let continue fall out so we wait either way
				
				await get_tree().create_timer(execution_min_time_ms / 1000.0).timeout
			
			# Need to get proper line_num
			line_num = skip_block(line_num_prev + 1, expected_indent_level, false)
			
			continue
		
		## Repeat loop END ##
		
		## While loop BEGIN ##
		
		var while_regex := RegEx.new()
		while_regex.compile("^while[\\s\\(](.*):")
		var while_regex_result := while_regex.search(stripped_line)
		if while_regex_result != null:
			var condition = while_regex_result.get_string(1)
			
			var line_num_prev = line_num
			var has_looped := false
			while true:
				if has_looped:
					await get_tree().create_timer(execution_min_time_ms / 1000.0).timeout
				has_looped = true
				
				var condition_result = await execute_expression(condition, line_num_prev)
				output_result(line_num_prev, condition_result)
				
				if context.dead or condition_result.status == ResultStatus.Failed:
					return %Editor.get_line_count()
				
				if not condition_result.value:
					break
				
				# This skip is just to clear the output
				skip_block(line_num_prev + 1, expected_indent_level, true)
				
				line_num = await execute_block(line_num_prev + 1, expected_indent_level + 1, true)
				if has_error:
					return %Editor.get_line_count()
				elif line_num is LoopControl:
					if line_num == LoopControl.CONTINUE:
						continue
					elif line_num == LoopControl.BREAK:
						break
			
			# Need to get proper line_num
			line_num = skip_block(line_num_prev + 1, expected_indent_level, false)
			
			continue
		
		## While loop END ##
		
		## Finally, just evaluate the single line
		
		var result := await execute_line(stripped_line, line_num)
		output_result(line_num, result)
		
		if context.dead or result.status == ResultStatus.Failed:
			return %Editor.get_line_count()
		
		line_num += 1
	
	return line_num

func execute_line(line:String, line_num:int) -> ExecutionResult:
	
	var variable_declair_regex = RegEx.new()
	variable_declair_regex.compile("^var\\s([a-zA-Z_][a-zA-Z_0-9]*)$")
	var variable_name_regex = RegEx.new()
	variable_name_regex.compile("^[a-zA-Z_][a-zA-Z_0-9]*$")
	
	var equals_regex = RegEx.new()
	equals_regex.compile("[^=!><]=[^=!><]")
	
	if equals_regex.search(line) != null:
		if not line.begins_with("var"):
			const operators = ["+", "-", "*", "/", "%"]
			for op in operators:
				var op_eq = op + "="
				if line.contains(op_eq):
					var sides = line.split(op_eq, true, 1)
					var var_name = sides[0].strip_edges()
					line = line.replace(op_eq, "= " + var_name + " " + op)
		var sides = line.split("=", true, 1)
		if len(sides) >= 2:
			var left_hand_side = sides[0].strip_edges()
			var variable_value = sides[1].strip_edges()
			var var_name = left_hand_side
			
			var var_regex_result = variable_declair_regex.search(left_hand_side)
			if var_regex_result != null:
				var_name = var_regex_result.get_string(1)
				%Editor.syntax_highlighter.add_member_keyword_color(var_name,MEMBER_KEYWORD_COLOUR)
				if var_name in keywords or var_name in control_flow_keywords:
					return ExecutionResult.new("cannot use %s as a variable name" % var_name, ResultStatus.Failed)
				# commenting this out for now until we support scoping in loops
				#if var_name in context.user_variables:
					## This is to account for dictionary assignment also adding the value
					#var correct_expression = "(use '" + var_name + " = " + variable_value + "' instead)"
					#return ExecutionResult.new("re-defined variable: only need var once " + correct_expression, ResultStatus.Failed)
			elif variable_name_regex.search(left_hand_side) != null:
				if !(var_name in context.user_variables):
					# This is to account for dictionary assignment also adding the value
					var correct_expression = "(use 'var " + line + "' instead)"
					return ExecutionResult.new("assignment to undefined variable " + correct_expression, ResultStatus.Failed)
			else:
				return ExecutionResult.new("Invalid variable name. Variable names can only contain letters, numbers, underscores, and cannot start with a number", ResultStatus.Failed)
			
			var evaluated_value = await execute_expression(variable_value, line_num)
			
			if evaluated_value.status == ResultStatus.Completed:
				context.user_variables[var_name] = evaluated_value.value
				update_var_display()
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
	return await execute_expression(line, line_num)

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
	%ExecutionTimer.start(seconds_remaining)
	await %ExecutionTimer.timeout

var last_executed_line := 0
func set_executing_line(line_num:int):
	%Editor.set_line_as_executing(last_executed_line, false)
	%Editor.set_line_as_executing(line_num, true)
	last_executed_line = line_num

func execute_expression(expr:String, line_num:int) -> ExecutionResult:
	
	set_executing_line(line_num)
	
	var end_ticks = Time.get_ticks_msec() + execution_min_time_ms
	expr = replace_vars_with_dictionaries(expr)
	
	var error = expression.parse(expr, ["DisplayServer", "TileInfo"])
	if error != OK:
		return ExecutionResult.new("Parse error: " + expression.get_error_text(), ResultStatus.Failed)
	var result = await expression.execute([DisplayServer, TileInfo], context)
	if kill_execution:
		return ExecutionResult.new("Execution stopped", ResultStatus.Failed)
	if not expression.has_execute_failed():
		await wait_for_ticks(end_ticks)
		if kill_execution:
			return ExecutionResult.new("Execution stopped", ResultStatus.Failed)
		return ExecutionResult.new(result)
	# something failed
	await wait_for_ticks(end_ticks)
	if kill_execution:
		return ExecutionResult.new("Execution stopped", ResultStatus.Failed)
	return ExecutionResult.new(expression.get_error_text(), ResultStatus.Failed)
	
func update_var_display() -> void:
	%Variables.text = ""
	for variable in context.user_variables:
		if variable is String:
			%Variables.add_text("%s: \"%s\"\n" % [variable, str(context.user_variables[variable])])
		else:
			%Variables.add_text("%s: %s\n" % [variable, str(context.user_variables[variable])])

enum ResultStatus {
	Completed,
	Failed,
	Skipped
}

class LoopControl:
	static var CONTINUE := LoopControl.new()
	static var BREAK := LoopControl.new()

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
