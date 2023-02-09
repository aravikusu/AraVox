extends Node

const aravox_funcs = ["#rand","#pl", "#if", "#choice"]

enum MustacheType {
	FUNCTION = 0,
	DATA = 1,
	SHORTHAND = 2,
	NONE = 99
}

var script_file = null
var current_data = []

var shorthands_location = "res://aravox_shorthands.tres"

var shorthands = null
var shorthands_are_loaded = false

func generate(script: String, data: Array = [], shorthands_override: String = "res://aravox_shorthands.tres") -> Dictionary:
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
	
	var res = _prepare_script()
	_flush()
	return res

# Loads the script file and starts preparing it for the in-game textboxes.
func _prepare_script() -> Dictionary:
	var file = FileAccess.open(script_file, FileAccess.READ)
	var prepared := {
		"script": [],
		"choices": []
	}
	
	var idx := 0
	while not file.eof_reached():
		var line = file.get_line()
		var fixed = mustache_replacer(line, idx, file)
		prepared.script.append_array(fixed.script)
		prepared.choices.append_array(fixed.choices)
		idx += 1
	
	return prepared

func mustache_replacer(line: String, idx: int = 0, file: FileAccess = null, increment_idx: int = 0) -> Dictionary:
	var new_things = {
		"script": [],
		"choices": []
	}
	
	var actual_idx = idx + increment_idx
	if line != "":
		var mustaches = get_all_mustaches(line)
		var fixed_line = line
		for mustache in mustaches:
			var result = null
			match mustache.type:
				MustacheType.FUNCTION:
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
				MustacheType.DATA:
					fixed_line = _data(fixed_line, mustache)
				MustacheType.SHORTHAND:
					fixed_line = _shorthands(fixed_line, mustache)
			
			if result != null:
				new_things.script.append_array(result.script)
				new_things.choices.append_array(result.choices)
		
		if fixed_line != "":
			new_things.script.append(fixed_line)
	return new_things

# AraVox rand: Shows one of the options the ones supplied by the script.
func _rand(line: String, mustache: Dictionary) -> String:
	var rnd = RandomNumberGenerator.new()
	rnd.randomize()
	
	var choice = mustache.vars[rnd.randi_range(0, mustache.vars.size() - 1)]
	return line.replace(mustache.full_stache, choice)

# AraVox pl: Takes an int and then selects one of the two supplied words.
func _pl(line: String, mustache: Dictionary) -> String:
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
func _if(all_lines: FileAccess, start_line: int, mustache: Dictionary) -> Dictionary:
	assert(mustache.vars.size() != 0, "AraVox: #if is missing variables.")
	var new_things = {
		"script": [],
		"choices": []
	}
	
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
		new_things.script.append_array(fixed.script)
		new_things.choices.append_array(fixed.choices)
		idx += 1
	
	return new_things

func _choice(all_lines: FileAccess, line_number: int, mustache: Dictionary) -> Dictionary:
	assert(mustache.vars.size() != 0, "AraVox: #choice needs to have at least one choice.")
	var new_things = {
		"script": [],
		"choices": []
	}
	var all = get_entire_choice(all_lines, line_number)
	var branches = []
	for branch in all:
		branches.append(branch.branch)
		if branch.choices.size() > 0:
			var idx = 0
			var fixed = []
			for choice in branch.choices:
				var temp = choice
				temp.appears_in_branch = idx
				fixed.append(temp)
			new_things.choices.append_array(fixed)
	
	var stuff = {
		"options": mustache.vars,
		"branches": branches,
		"appears_on": line_number,
		"appears_in_branch": -1
	}
	new_things.choices.append(stuff)
	return new_things

# AraVox data: replaces instances of $# with their respective data.
func _data(line: String, mustache: Dictionary) -> String:
	return line.replace(mustache.full_stache, get_specific_data(mustache.name))

# AraVox shorthands: replaces instances of %"" with hard values.
func _shorthands(line: String, mustache: Dictionary) -> String:
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
func get_all_mustaches(line: String) -> Array[Dictionary]:
	var mustaches : Array[Dictionary]
	
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

func prepare_mustache(mustache_contents: String) -> Dictionary:
	var mustache_name = mustache_contents.split(" ")[0]
	
	var mustache_vars = mustache_contents.replace(mustache_name, "")
	
	var mustache_arr = []
	for m_var in mustache_vars.split(","):
		var variable = m_var
		while variable.find(" ") == 0:
			variable = variable.trim_prefix(" ")
		mustache_arr.append(variable)
	
	var mustache_type = MustacheType.NONE
	
	if mustache_name in aravox_funcs:
		mustache_type = MustacheType.FUNCTION
		
	if shorthands != null:
		if mustache_name in shorthands.shorthands.keys():
			mustache_type = MustacheType.SHORTHAND
	
	if mustache_name.contains("$"):
		mustache_type = MustacheType.DATA
	
	assert(mustache_type != MustacheType.NONE, "AraVox: Illegal mustache: \"" + mustache_name + "\". Did you perhaps forget your shorthands?")
	
	var mustache_dict = {
		"type": mustache_type,
		"name": mustache_name,
		"vars": mustache_arr,
		"full_stache": "{{" + mustache_contents +  "}}"
	}
	
	return mustache_dict

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
func get_entire_choice(all_lines: FileAccess, line_number: int) -> Array:
	var branches = []
	
	var current_branch = {
		"branch": [],
		"choices": []
	}
	var found_end = false
	var idx = 0
	while not all_lines.eof_reached():
		var current = all_lines.get_line()
		if current == "{{#branch}}":
			continue
		elif current == "{{/branch}}":
			branches.append(current_branch)
			current_branch = {
				"branch": [],
				"choices": []
			}
			idx = 0
			continue
		elif current == "{{/choice}}":
			found_end = true
			break
		
		var fixed = mustache_replacer(current, line_number, all_lines, idx)
		if fixed.script.size() > 0:
			current_branch.branch.append_array(fixed.script)
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

func _flush():
	script_file = null
	current_data = []
