extends Node

const aravox_funcs: Array[String] = ["#rand","#pl", "#if", "#choice"]

var script_file: String = ""
var current_data: Array = []

var shorthands_location: String = "res://aravox_shorthands.tres"

var shorthands: AraVoxShorthands = null
var shorthands_are_loaded: bool = false

func generate(script: String, data: Array = [], shorthands_override: String = "res://aravox_shorthands.tres") -> AraVoxScript:
	script_file = script
	current_data = data
	
	if shorthands_override != shorthands_location:
		shorthands_location = "res://" + shorthands_override + "/aravox_shorthands.tres"
		shorthands_are_loaded = false
	
	if !shorthands_are_loaded:
		if ResourceLoader.exists(shorthands_location):
			shorthands = load(shorthands_location)
			assert(shorthands.get("shorthands") != null, "Supplied shorthands resource is not of type AraVoxShorthands.")
		else:
			print("AraVox: Could not find shorthands resource.")
	
	var res: AraVoxScript = _prepare_script()
	_flush()
	return res

# Loads the script file and starts preparing it for the in-game textboxes.
func _prepare_script() -> AraVoxScript:
	var file: FileAccess = FileAccess.open(script_file, FileAccess.READ)
	var prepared: AraVoxScript = AraVoxScript.new()
	
	var idx: int = 0
	while not file.eof_reached():
		var line: String = file.get_line()
		var fixed: AraVoxScript = mustache_replacer(line, idx, file)
		prepared._script.append_array(fixed._script)
		prepared.choices.append_array(fixed.choices)
		idx += 1
	
	file.close()
	return prepared

func mustache_replacer(line: String, idx: int = 0, file: FileAccess = null, increment_idx: int = 0) -> AraVoxScript:
	var new_things: AraVoxScript = AraVoxScript.new()
	
	var actual_idx: int = idx + increment_idx
	if line != "":
		var mustaches: Array[AraVoxMustache] = get_all_mustaches(line)
		var fixed_line: String = line
		for mustache: AraVoxMustache in mustaches:
			var result = null
			match mustache.type:
				AraVoxMustache.MustacheType.FUNCTION:
					match mustache.name:
							"#rand":
								fixed_line = _rand(fixed_line, mustache)
							"#pl":
								fixed_line = _pl(fixed_line, mustache)
							"#if":
								result = _if(file, actual_idx, mustache)
								fixed_line = ""
							"#choice":
								result = _choice(file, actual_idx, mustache)
								fixed_line = ""
				AraVoxMustache.MustacheType.DATA:
					fixed_line = _data(fixed_line, mustache)
				AraVoxMustache.MustacheType.SHORTHAND:
					fixed_line = _shorthands(fixed_line, mustache)
			
			if result != null:
				new_things._script.append_array(result._script)
				new_things.choices.append_array(result.choices)
		
		if fixed_line != "":
			new_things._script.append(fixed_line)
	return new_things

# AraVox rand: Shows one of the options the ones supplied by the script.
func _rand(line: String, mustache: AraVoxMustache) -> String:
	var rnd = RandomNumberGenerator.new()
	rnd.randomize()
	
	var choice = mustache.vars[rnd.randi_range(0, mustache.vars.size() - 1)]
	return line.replace(mustache.full_stache, choice)

# AraVox pl: Takes an int and then selects one of the two supplied words.
func _pl(line: String, mustache: AraVoxMustache) -> String:
	var num = 0
	var choice = ""
	
	if is_this_data(mustache.vars[0]):
		num = get_specific_data(mustache.vars[0])
	
	if int(num) == 1:
		choice = mustache.vars[1]
	else:
		choice = mustache.vars[2]
	
	return line.replace(mustache.full_stache, choice)

# AraVox if: Checks if supplied condition is truthy, then displays the correct line.
func _if(all_lines: FileAccess, start_line: int, mustache: AraVoxMustache) -> AraVoxScript:
	assert(mustache.vars.size() != 0, "AraVox: #if is missing variables.")
	var new_things: AraVoxScript = AraVoxScript.new()
	
	var all = get_entire_if(all_lines)
	var value1
	if is_this_data(mustache.vars[0]):
		value1 = get_specific_data(mustache.vars[0])
	else:
		value1 = mustache.vars[0]
	
	var is_truthy = false
	if mustache.vars.size() > 1:
		var value2
		var operator = mustache.vars[1]
		
		if is_this_data(mustache.vars[2]):
			value2 = get_specific_data(mustache.vars[2])
		else:
			value2 = mustache.vars[2]
		
		match operator:
			"==":
				if value1 == value2: is_truthy = true
			"!=":
				if value1 != value2: is_truthy = true
			">":
				if value1 > value2: is_truthy = true
			"<":
				if value1 < value2: is_truthy = true
	else:
		if bool(int(value1)): is_truthy = true
	
	var lines = []
	if is_truthy:
		lines = all.if_block
	else:
		lines = all.else_block
	
	var idx = 0
	for line in lines:
		var fixed = mustache_replacer(line, start_line, all_lines, idx)
		new_things._script.append_array(fixed._script)
		new_things.choices.append_array(fixed.choices)
		idx += 1
	
	return new_things

func _choice(all_lines: FileAccess, line_number: int, mustache: AraVoxMustache) -> AraVoxScript:
	assert(mustache.vars.size() != 0, "AraVox: #choice needs to have at least one choice.")
	var new_things: AraVoxScript = AraVoxScript.new()

	var all: Array[AraVoxBranch] = get_entire_choice(all_lines, line_number)
	var branches: Array = []
	for branch: AraVoxBranch in all:
		branches.append(branch.branch)
		if branch.choices.size() > 0:
			var idx: int = 0
			var fixed = []
			for choice: AraVoxChoice in branch.choices:
				var temp: AraVoxChoice = choice
				temp.appears_in_branch = idx
				fixed.append(temp)
			new_things.choices.append_array(fixed)
	
	var stuff: AraVoxChoice = AraVoxChoice.new()
	stuff.options = mustache.vars
	stuff.branches = branches
	stuff.appears_on = line_number
	stuff.appears_in_branch = -1
	
	new_things.choices.append(stuff)
	return new_things

# AraVox data: replaces instances of $# with their respective data.
func _data(line: String, mustache: AraVoxMustache) -> String:
	return line.replace(mustache.full_stache, get_specific_data(mustache.name))

# AraVox shorthands: replaces instances of %"" with hard values.
func _shorthands(line: String, mustache: AraVoxMustache) -> String:
	var fixed = line
	if shorthands != null:
		var keys = shorthands.shorthands.keys()
		var values = shorthands.shorthands.values()
		for i in shorthands.shorthands.size():
			var key = keys[i]
			if mustache.name == key:
				var value = values[i]
				fixed = fixed.replace(mustache.full_stache, value)
	return fixed

# Helpers below...

# Returns all found mustaches on a line.
func get_all_mustaches(line: String) -> Array[AraVoxMustache]:
	var mustaches : Array[AraVoxMustache]
	
	var remaining = line
	var keep_searching = true
	var idx = 0
	while keep_searching:
		if remaining.contains("{{"):
			assert(idx != 1000, "AraVox: Unable to find closing mustache for line: " + remaining + " after 1000 iterations. Ceasing operation; check for broken mustaches.")
			var mustache = find_between(remaining, "{{", "}}")
			
			mustaches.append(prepare_mustache(mustache))
			
			remaining = remaining.replace("{{" + mustache + "}}", "")
		else:
			keep_searching = false
		idx += 1
	return mustaches

func prepare_mustache(mustache_contents: String) -> AraVoxMustache:
	var mustache_name: String = mustache_contents.split(" ")[0]
	
	var mustache_vars: String = mustache_contents.replace(mustache_name, "")
	
	var mustache_arr: Array[String] = []
	for m_var: String in mustache_vars.split(","):
		var variable: String = m_var
		while variable.find(" ") == 0:
			variable = variable.trim_prefix(" ")
		mustache_arr.append(variable)
	
	var mustache_type: AraVoxMustache.MustacheType = AraVoxMustache.MustacheType.NONE
	
	if mustache_name in aravox_funcs:
		mustache_type = AraVoxMustache.MustacheType.FUNCTION
		
	if shorthands != null:
		if mustache_name in shorthands.shorthands.keys():
			mustache_type = AraVoxMustache.MustacheType.SHORTHAND
	
	if mustache_name.contains("$"):
		mustache_type = AraVoxMustache.MustacheType.DATA
	
	assert(mustache_type != AraVoxMustache.MustacheType.NONE, "AraVox: Illegal mustache: \"" + mustache_name + "\". Did you perhaps forget your shorthands?")
	
	var mustache: AraVoxMustache = AraVoxMustache.new()
	mustache.type = mustache_type
	mustache.name = mustache_name
	mustache.vars = mustache_arr
	mustache.full_stache = "{{" + mustache_contents +  "}}"
	
	return mustache

# Iterate through the entire #if block and return it in a nice dictionary.
func get_entire_if(all_lines: FileAccess) -> Dictionary:
	var stuff = {
		"if_block": [],
		"else_block": [],
	}
	
	var if_block = true
	var found_end = false
	while not all_lines.eof_reached():
		var current = all_lines.get_line()
		if current == "{{#else}}": 
			if_block = false
			continue
		elif current =="{{/if}}":
			found_end = true
			break
		
		if if_block:
			stuff.if_block.append(current)
		else:
			stuff.else_block.append(current)
	
	assert(found_end, "AraVox: {{#if}} used but could not find matching {{/if}}. Error thrown as this will very likely break your script.")
	
	return stuff

# Similar to the #if version, but this time returns all the branches.
func get_entire_choice(all_lines: FileAccess, line_number: int) -> Array[AraVoxBranch]:
	var branches: Array[AraVoxBranch] = []
	
	var current_branch: AraVoxBranch = AraVoxBranch.new()
	var found_end: bool = false
	var idx: int = 0
	while not all_lines.eof_reached():
		var current: String = all_lines.get_line()
		if current == "{{#branch}}":
			continue
		elif current == "{{/branch}}":
			branches.append(current_branch)
			current_branch = AraVoxBranch.new()
			idx = 0
			continue
		elif current == "{{/choice}}":
			found_end = true
			break
		
		var fixed = mustache_replacer(current, line_number, all_lines, idx)
		if fixed._script.size() > 0:
			current_branch.branch.append_array(fixed._script)
			idx += 1
		
		if fixed.choices.size() > 0:
			current_branch.choices.append_array(fixed.choices)
			idx += 1
	assert(found_end, "AraVox: {{#choice}} used but could not find matching {{/choice}}. Error thrown as this will very likely break your script.")
	
	return branches

func is_this_data(maybe_data: String) -> bool:
	var well_is_it = false
	if maybe_data[0] == "$":
		assert(current_data.size() > 0, "AraVox: Your function call contains data requests, but you have not supplied any data.")
		well_is_it = true
	return well_is_it

# Returns the data with the supplied index.
func get_specific_data(data_index: String) -> String:
	assert(current_data.size() >= int(data_index.replace("$", "")), "AraVox: You've requested data index " + data_index + " when the data_array only has " + str(current_data.size()) + " elements.")
	return str(current_data[int(data_index.replace("$", ""))])

# Returns everything between two points in a string.
func find_between(line: String, first: String, last: String) -> String:
	return(line.split(first))[1].split(last)[0]

func _flush() -> void:
	script_file = ""
	current_data = []
