extends CanvasLayer

@export
var context:Node = null

var expression = Expression.new()

const KEYWORD_COLOUR = Color(0xff7085ff)
const CONTROL_FLOW_KEYWORD_COLOUR = Color(0xff8cccff)
const MEMBER_KEYWORD_COLOUR = Color(0xbce0ffff)

func _ready():
	for x in [%Input,%Output,%Variables]:
		x.syntax_highlighter.function_color = Color(0x57b3ffff)
		x.syntax_highlighter.number_color = Color(0xa1ffe0ff)
		x.syntax_highlighter.member_variable_color = Color(0xbce0ffff)
		x.syntax_highlighter.symbol_color = Color(0xabc9ffff)
		
		x.syntax_highlighter.add_color_region("\"","\"",Color(0xffeda1ff),true)
		x.syntax_highlighter.add_color_region("#","",Color(0xcdcfd280),true)
		x.syntax_highlighter.add_color_region("!!","",Color(0xff786bff),true)
		
		x.syntax_highlighter.add_keyword_color("var",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("true",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("false",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("in",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("func",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("const",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("await",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("and",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("or",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("not",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("null",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("self",KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("ERROR",KEYWORD_COLOUR)
		
		x.syntax_highlighter.add_keyword_color("for",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("if",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("elif",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("else",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("return",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("break",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("continue",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("pass",CONTROL_FLOW_KEYWORD_COLOUR)
		x.syntax_highlighter.add_keyword_color("while",CONTROL_FLOW_KEYWORD_COLOUR)

func _on_go_pressed() -> void:
	var code = %Input.text
	var result:ExecutionResult
	var line_num := 1
	
	%Reset.show()
	%GO.hide()
	
	%Output.show()
	%Output.text = ""
	
	for line in code.split('\n'):
		# Remove comments
		line = line.split("#", true, 1)[0]
		# Remove whitespace
		line = line.strip_edges()
		if line == "":
			# ignore empty lines
			continue
		
		%Output.text += "%s: " % [line]
		result = await execute_line(line)
		
		if result.status == ResultStatus.Completed:
			%Output.text += "#" + result.value_str + "\n"
		else:
			%Output.text += "!!ERROR " + result.value_str + "\n"
			break
		line_num = line_num + 1
	%Output.text += "Done!\n"
	update_var_display()

func _on_reset_pressed():
	LevelManager.load_current()
	%Output.text = ""
	%Input.show()
	
	%Reset.hide()
	%GO.show()

func execute_line(line:String) -> ExecutionResult:
	
	var regex = RegEx.new()
	regex.compile("[^=!><]=[^=!><]")
	
	if regex.search(line) != null:
		var sides = line.split("=", true, 1)
		if len(sides) >= 2:
			var left_hand_side = sides[0].strip_edges()
			var variable_value = replace_vars_with_dictionaries(sides[1].strip_edges())
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
				%Input.syntax_highlighter.add_member_keyword_color(var_name,MEMBER_KEYWORD_COLOUR)
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
	else:
		line = replace_vars_with_dictionaries(line)
	
	print("final line: ", line)
	return await execute_expression(line)

func replace_vars_with_dictionaries(expr:String) -> String:
	# TODO: There's a better way to do this...
	for var_name in context.user_variables.keys():
		var regex = RegEx.new()
		regex.compile("\\b" + var_name + "\\b")
		expr = regex.sub(expr, "user_variables[\""+var_name+"\"]", true)
	
	return expr

func execute_expression(expr:String) -> ExecutionResult:
	var error = expression.parse(expr, ["DisplayServer"])
	if error != OK:
		return ExecutionResult.new("Parse error: " + expression.get_error_text(), ResultStatus.Failed)
	var result = await expression.execute([DisplayServer], context)
	if not expression.has_execute_failed():
		return ExecutionResult.new(result)
	# something failed
	context.trigger_death()
	return ExecutionResult.new(expression.get_error_text(), ResultStatus.Failed)
	
func update_var_display() -> void:
	%Variables.text = ""
	for variable in context.user_variables:
		%Variables.text += "%s: %s\n" % [variable, str(context.user_variables[variable])]
		
func on_player_death(line) -> void:
	# stop executing any code
	pass

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
