extends Control

signal script_generation_finished(script: Dictionary)

## The script file that this AraVoxController should handle.
@export_file("*.txt") var dialogue_file
## The data that should be supplied to this script.
@export var dialogue_data := []

## This lets you override that location to any folder in your project.[br]
##By default AraVox will look in your folder root.
@export var shorthands_override := ""

func generate():
	assert(dialogue_file != null, "You must supply a dialogue file in order to generate it.")
	
	if shorthands_override == "":
		shorthands_override = "res://aravox_shorthands.tres"
	var dialogue = AraVox.generate(dialogue_file, dialogue_data, shorthands_override)
	emit_signal("script_generation_finished", dialogue)
