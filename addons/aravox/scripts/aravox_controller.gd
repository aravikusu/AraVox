## Handles the generation of an AraVox script.
class_name AraVoxController extends Control

signal script_generation_finished(script: AraVoxScript)

## The script file that this AraVoxController should handle.
@export_file("*.txt") var dialogue_file
## The data that should be supplied to this script.
@export var dialogue_data: Array = []

## This lets you override that location to any folder in your project.[br]
##By default AraVox will look in your folder root.
@export var shorthands_override: String = ""

func generate():
	assert(dialogue_file != null, "You must supply a dialogue file in order to generate it.")
	
	if shorthands_override == "":
		shorthands_override = "res://aravox_shorthands.tres"
	var dialogue: AraVoxScript = AraVox.generate(dialogue_file, dialogue_data, shorthands_override)
	emit_signal("script_generation_finished", dialogue)
