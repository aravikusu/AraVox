extends Node

var script_file = null
var current_data = []

var shorthands_location = "res://aravox_shorthands.tres"

var shorthands = null
var shorthands_are_loaded = false

func generate(script: String, data: Array = [], shorthands_override: String = "res://aravox_shorthands.tres") -> Array[String]:
	script_file = script
	current_data = data
	
	if shorthands_override != shorthands_location:
		shorthands_location = "res://" + shorthands_override + "aravox_shorthands.tres"
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
			assert(line == "## ARAVOX SCRIPT ##", "Aratalk Script is missing the validation header")
		else:
			if line != "":
				var fixed_line = line
				fixed_line = _rand(fixed_line)
				fixed_line = _pl(fixed_line)
				fixed_line = _data(fixed_line)
				fixed_line = _shorthands(fixed_line)
				prepared.append(fixed_line)
		idx += 1
	return prepared

# AraTalk rand: Shows one of the options the ones supplied by the script.
func _rand(line: String) -> String:
	if line.contains("rand{"):
		var rand = RandomNumberGenerator.new()
		rand.randomize()
		
		var stuff_between = find_between(line, "rand{", "}")
		var options = stuff_between.split("|")
		var fixed = line.replace("rand{" + stuff_between + "}", options[rand.randi_range(0, options.size() - 1)])
		
		return fixed
	else:
		return line

# AraVox pl: Takes an int and then selects one of the two supplied words.
func _pl(line: String) -> String:
	if (line.contains("pl{")):
		var stuff_between = find_between(line, "pl{", "}")
		var options = stuff_between.split("|")
		var choice = ""
		
		var dataIndex = "$" + options[0]
		if int(get_specific_data(dataIndex)) == 1:
			choice = options[1]
		else:
			choice = options[2]
		return line.replace("pl{" + stuff_between + "}", choice)
	else:
		return line

# AraVox data: replaces instances of $# with their respective data.
func _data(line: String) -> String:
	if current_data.size() > 0:
		if line.contains("$"):
			var fixed = line
			for i in current_data.size():
				var dataIndex = "$" + str(i)
				fixed = fixed.replace(dataIndex, get_specific_data(dataIndex))
			return fixed
		else:
			return line
	else:
		return line

# AraVox shorthands: replaces instances of %"" with hard values.
func _shorthands(line: String) -> String:
	var fixed = line
	if shorthands != null:
		for i in shorthands.shorthands.size():
			var key = shorthands.keys[i]
			var value = shorthands.values[i]
			fixed = fixed.replace(key, value)
	return line

# Helpers below...

# Returns the data with the supplied index.
func get_specific_data(dataIndex: String) -> String:
	assert(dataIndex[0] == "$")
	return str(current_data[int(dataIndex.replace("$", ""))])

# Returns everything between two points in a string.
func find_between(line: String, first: String, last: String) -> String:
	return(line.split(first))[1].split(last)[0]

func _flush():
	script_file = null
	current_data = []
