extends Node

const aravox_funcs = ["#rand","#pl", "#if"]

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

func generate(script: String, data: Array = [], shorthands_override: String = "res://aravox_shorthands.tres") -> Array[String]:
	script_file = script
	current_data = data
	
	if shorthands_override != shorthands_location:
		shorthands_location = "res://" + shorthands_override + "/aravox_shorthands.tres"
		shorthands_are_loaded = false
	
	if !shorthands_are_loaded:
		if ResourceLoader.exists(shorthands_location):
			shorthands = load(shorthands_location)
	
	var fixed = _prepare_script()
	_flush()
	return fixed

# Loads the script file and starts preparing it for the in-game textboxes.
func _prepare_script() -> Array[String]:
	var file = FileAccess.open(script_file, FileAccess.READ)
	
	var prepared := []
	var idx := 0
	while not file.eof_reached():
		var line = file.get_line()
		if idx == 0:
			# Basic file validation, if the file isn't a script file, error out
			assert(line == "## ARAVOX SCRIPT ##", "AraVox: Validation header missing.")
		else:
			if line != "":
				# Get every mustache found on this line
				var mustaches = get_all_mustaches(line)
				var fixed_line = line
				
				for mustache in mustaches:
					match mustache.type:
						MustacheType.FUNCTION:
							match mustache.name:
								"#rand":
									fixed_line = _rand(fixed_line, mustache)
								"#pl":
									fixed_line = _pl(fixed_line, mustache)
						MustacheType.DATA:
							fixed_line = _data(fixed_line, mustache)
						MustacheType.SHORTHAND:
							fixed_line = _shorthands(fixed_line, mustache)
				prepared.append(fixed_line)
		idx += 1
	print(prepared)
	return prepared

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
	
	if num == 1:
		choice = mustache.vars[1]
	else:
		choice = mustache.vars[2]
	
	return line.replace(mustache.full_stache, choice)

# AraVox data: replaces instances of $# with their respective data.
func _data(line: String, mustache: Dictionary) -> String:
	return line.replace(mustache.full_stache, get_specific_data(mustache.name))

# AraVox shorthands: replaces instances of %"" with hard values.
func _shorthands(line: String, mustache: Dictionary) -> String:
	print(mustache)
	var fixed = line
	if shorthands != null:
		for i in shorthands.shorthands.size():
			var key = shorthands.keys[i]
			var value = shorthands.values[i]
			fixed = fixed.replace(key, value)
	return line

# Helpers below...

# Returns all found mustaches on a line.
func get_all_mustaches(line: String) -> Array[Dictionary]:
	var mustaches = []
	
	var remaining = line
	var keep_searching = true
	while keep_searching:
		if remaining.contains("{{"):
			var mustache = find_between(remaining, "{{", "}}")
			mustaches.append(prepare_mustache(mustache))
			
			remaining = remaining.replace("{{" + mustache + "}}", "")
		else:
			keep_searching = false
	return mustaches

func prepare_mustache(mustache_contents: String) -> Dictionary:
	var mustache_arr = mustache_contents.split(" ")
	var mustache_name = mustache_arr[0]
	var mustache_type = MustacheType.NONE
	mustache_arr.remove_at(0)
	
	if mustache_name in aravox_funcs:
		mustache_type = MustacheType.FUNCTION
		
	if shorthands != null: 
		if mustache_name in shorthands.shorthands:
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

func is_this_data(maybe_data: String) -> bool:
	var well_is_it = false
	if maybe_data[0] == "$":
		assert(current_data.size() > 0, "AraVox: Your function call contains data requests, but you have not supplied any data.")
		well_is_it == true
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
