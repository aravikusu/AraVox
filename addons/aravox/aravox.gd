extends Node

const aravox_builtins: Array[String] = ["#rand", "#pl", "#if", "#choice", "#action"]

var script_file: String = ""
var current_data: Dictionary = {}

var config_location: String = "res://aravox_config.tres"

var config: AraVoxConfig = null
var shorthands_are_loaded: bool = false

var registered_actions: Dictionary[String, Callable] = {}

# Classes
class Line:
	## The... speaker, of the line, as it were.
	var speaker: String = ""
	## The text line itself.
	var line: String = ""

class Choice:
	## The options the player interacts with.
	var options: Array[String] = []
	## Each element is an Array of (AraVoxLine | AraVoxChoice | AraVoxAction).
	var branches: Array = []

class Conditional:
	## Raw condition tokens e.g. ["$gold", "==", "5"]
	var condition_vars: Array[String] = []
	var if_block: Array = []
	var else_block: Array = []

class Action:
	## The actual function this action calls.
	var function: Callable
	## The function's properties, supplied by the script.
	var func_props: Array[String] = []

	func call_action() -> void:
		function.call(func_props)

func register_action(name: String, function: Callable) -> void:
	registered_actions[name] = function

func generate(script: String, data: Dictionary = {}, config_override: String = "res://aravox_config.tres") -> Array:
	script_file = script
	current_data = data

	if config_override != config_location:
		config_location = "res://" + config_override + "/aravox_config.tres"
		shorthands_are_loaded = false

	if !shorthands_are_loaded:
		if ResourceLoader.exists(config_location):
			config = load(config_location)
			assert(config.get("shorthands") != null, "Supplied config resource is not of type AraVoxConfig.")
		else:
			print("AraVox: Could not find shorthands resource.")

	var res: Array = _prepare_script()
	_flush()
	return res

## Loads the script file and starts preparing it for the in-game textboxes.
func _prepare_script() -> Array:
	var file: FileAccess = FileAccess.open(script_file, FileAccess.READ)
	var prepared: Array = []

	while not file.eof_reached():
		var line: String = file.get_line()
		if line.begins_with("#"):
			continue
		prepared.append_array(mustache_replacer(line, file))

	file.close()
	return prepared

func mustache_replacer(line: String, file: FileAccess = null) -> Array:
	var new_things: Array = []

	if line != "":
		var mustaches: Array[AraVoxMustache] = get_all_mustaches(line)
		var fixed_line: String = line
		for mustache: AraVoxMustache in mustaches:
			var result: Array = []
			match mustache.type:
				AraVoxMustache.MustacheType.FUNCTION:
					match mustache.name:
							"#rand":
								fixed_line = _rand(fixed_line, mustache)
							"#pl":
								fixed_line = _pl(fixed_line, mustache)
							"#if":
								result = _if(file, mustache)
								fixed_line = ""
							"#choice":
								result = _choice(file, mustache)
								fixed_line = ""
							"#action":
								new_things.append(_action(mustache))
								fixed_line = ""
				AraVoxMustache.MustacheType.DATA:
					fixed_line = _data(fixed_line, mustache)
				AraVoxMustache.MustacheType.SHORTHAND:
					fixed_line = _shorthands(fixed_line, mustache)

			if result.size() > 0:
				new_things.append_array(result)

		if fixed_line != "":
			new_things.append(_parse_line(fixed_line.replace("\\{{", "{{")))
	return new_things

## AraVox rand: Shows one of the options the ones supplied by the script.
func _rand(line: String, mustache: AraVoxMustache) -> String:
	randomize()
	
	var choice: String = mustache.vars[randi_range(0, mustache.vars.size() - 1)]
	return line.replace(mustache.full_stache, choice)

## AraVox pl: Takes an int and then selects one of the two supplied words.
func _pl(line: String, mustache: AraVoxMustache) -> String:
	var num: String = mustache.vars[0]
	var choice: String = ""
	
	if is_this_data(num):
		num = get_specific_data(mustache.vars[0])
	
	if int(num) == 1:
		choice = mustache.vars[1]
	else:
		choice = mustache.vars[2]
	
	return line.replace(mustache.full_stache, choice)

## AraVox if: Checks if supplied condition is truthy, then displays the correct line.
func _if(all_lines: FileAccess, mustache: AraVoxMustache) -> Array:
	assert(mustache.vars.size() != 0, "AraVox: #if is missing variables.")

	var all: Dictionary[String, Array] = get_entire_if(all_lines)
	var conditional: Conditional = Conditional.new()
	conditional.condition_vars = mustache.vars

	for line in all.if_block:
		conditional.if_block.append_array(mustache_replacer(line, all_lines))
	for line in all.else_block:
		conditional.else_block.append_array(mustache_replacer(line, all_lines))

	return [conditional]

## Make a choice... perhaps you accept the deal, or not.
func _choice(all_lines: FileAccess, mustache: AraVoxMustache) -> Array:
	assert(mustache.vars.size() != 0, "AraVox: #choice needs to have at least one choice.")

	var choice: Choice = Choice.new()
	choice.options = mustache.vars
	for branch in get_entire_choice(all_lines):
		choice.branches.append(branch)

	return [choice]

## AraVox action: effectively a function call to whichever function you sent in.
func _action(mustache: AraVoxMustache) -> Action:
	var func_name: String = mustache.vars[0]
	assert(func_name in registered_actions, "AraVox: There is no Action with the name " + func_name + " registered. Be sure to call register_action with the name & Callable you want to use.")

	var action: Action = Action.new()
	var func_props: Array[String] = []

	for prop: String in mustache.vars:
		var real_prop: String = get_specific_data(prop) if is_this_data(prop) else prop
		func_props.append(real_prop)
	func_props.pop_front()

	action.function = registered_actions[func_name]
	action.func_props = func_props

	return action

## AraVox data: replaces instances of $# with their respective data.
func _data(line: String, mustache: AraVoxMustache) -> String:
	return line.replace(mustache.full_stache, get_specific_data(mustache.name))

## AraVox shorthands: replaces instances of %"" with hard values.
func _shorthands(line: String, mustache: AraVoxMustache) -> String:
	var fixed: String = line
	if config != null:
		var keys: Array = config.shorthands.keys()
		var values: Array = config.shorthands.values()
		for i in config.shorthands.size():
			var key: String = keys[i]
			if mustache.name.replace("%", "") == key:
				var value: String = values[i]
				fixed = fixed.replace(mustache.full_stache, value)
	return fixed

# Helpers below...

## Parses the line, currently grabs [Speaker] tags.
func _parse_line(text: String) -> Line:
	var av_line: Line = Line.new()
	if text.begins_with("["):
		var close: int = text.find("]")
		if close != -1:
			av_line.speaker = text.substr(1, close - 1)
			av_line.line = text.substr(close + 1).strip_edges()
			return av_line
	av_line.line = text
	return av_line

## Returns all found mustaches on a line.
func get_all_mustaches(line: String) -> Array[AraVoxMustache]:
	var mustaches: Array[AraVoxMustache]
	for span in _scan_line_for_mustaches(line):
		mustaches.append(prepare_mustache(span))
	return mustaches

## Going through the line by character, getting all the parameters of each mustache
func _scan_line_for_mustaches(line: String) -> Array[String]:
	var spans: Array[String] = []
	var i: int = 0
	while i < line.length() - 1:
		if line[i] == '{' && line[i + 1] == '{':
			if i > 0 && line[i - 1] == '\\':
				i += 2
				continue
			i += 2
			var contents: String = ""
			while i < line.length() - 1:
				if line[i] == '}' && line[i + 1] == '}':
					spans.append(contents)
					i += 2
					break
				contents += line[i]
				i += 1
		else:
			i += 1
	return spans

## Splits comma-separated mustache arguments.
func _tokenize_args(raw: String) -> Array[String]:
	var tokens: Array[String] = []
	var current: String = ""
	var in_quotes: bool = false
	for ch in raw:
		if ch == '"':
			in_quotes = !in_quotes
		elif ch == ',' && !in_quotes:
			tokens.append(current.strip_edges())
			current = ""
		else:
			current += ch
	if not current.strip_edges().is_empty():
		tokens.append(current.strip_edges())
	return tokens

## Prepare the mustache so we can later correctly handle them based on what they are.
func prepare_mustache(mustache_contents: String) -> AraVoxMustache:
	var space_idx: int = mustache_contents.find(" ")
	var mustache_name: String
	var mustache_arr: Array[String]
	if space_idx == -1:
		mustache_name = mustache_contents
		mustache_arr = []
	else:
		mustache_name = mustache_contents.left(space_idx)
		mustache_arr = _tokenize_args(mustache_contents.substr(space_idx + 1))
	
	var mustache_type: AraVoxMustache.MustacheType = AraVoxMustache.MustacheType.NONE
	
	if mustache_name in aravox_builtins:
		mustache_type = AraVoxMustache.MustacheType.FUNCTION
		
	if config != null && mustache_name.contains("%"):
		if mustache_name.replace("%", "") in config.shorthands.keys():
			mustache_type = AraVoxMustache.MustacheType.SHORTHAND
	
	if mustache_name.contains("$"):
		mustache_type = AraVoxMustache.MustacheType.DATA
	
	assert(mustache_type != AraVoxMustache.MustacheType.NONE, "AraVox: Illegal mustache: \"" + mustache_name + "\". Did you perhaps forget your shorthands?")
	
	var mustache: AraVoxMustache = AraVoxMustache.new()
	mustache.type = mustache_type
	mustache.name = mustache_name
	mustache.vars = mustache_arr
	mustache.full_stache = "{{" + mustache_contents + "}}"
	
	return mustache

## Iterate through the entire #if block and return it in a 'nice' dictionary.
func get_entire_if(all_lines: FileAccess) -> Dictionary[String, Array]:
	var stuff: Dictionary[String, Array] = {
		"if_block": [],
		"else_block": [],
	}
	
	var if_block: bool = true
	var found_end: bool = false
	while !all_lines.eof_reached():
		var current: String = all_lines.get_line()
		if current == "{{#else}}":
			if_block = false
			continue
		elif current == "{{/if}}":
			found_end = true
			break
		
		if if_block:
			stuff.if_block.append(current)
		else:
			stuff.else_block.append(current)
	
	assert(found_end, "AraVox: {{#if}} used but could not find matching {{/if}}. Error thrown as this will very likely break your script.")
	
	return stuff

# Similar to the #if version, but this time returns all the branches.
func get_entire_choice(all_lines: FileAccess) -> Array:
	var branches: Array = []

	var current_branch: Array = []
	var found_end: bool = false
	while !all_lines.eof_reached():
		var current: String = all_lines.get_line()
		if current == "{{#branch}}":
			continue
		elif current == "{{/branch}}":
			branches.append(current_branch)
			current_branch = []
			continue
		elif current == "{{/choice}}":
			found_end = true
			break

		current_branch.append_array(mustache_replacer(current, all_lines))

	assert(found_end, "AraVox: {{#choice}} used but could not find matching {{/choice}}. Error thrown as this will very likely break your script.")
	return branches

func is_this_data(maybe_data: String) -> bool:
	var well_is_it: bool = false
	if maybe_data[0] == "$":
		assert(current_data.size() > 0, "AraVox: Your function call contains data requests, but you have not supplied any data.")
		well_is_it = true
	return well_is_it

# Returns the data with the supplied index.
func get_specific_data(data: String) -> String:
	var removed_prefix: String = data.replace("$", "")
	assert(removed_prefix.replace("$", "") in current_data, "AraVox: The data %s does not exist in the data Dictionary")
	return str(current_data[removed_prefix])

func _flush() -> void:
	script_file = ""
	current_data = {}
