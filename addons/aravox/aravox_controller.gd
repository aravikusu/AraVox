extends Control

signal script_generation_finished(script: Array[String])

## The script file that this AraVoxController should handle.
@export_file(".txt, .ara") var dialogue_file
## The data that should be supplied to this script.
@export var dialogue_data := []

## This lets you override that location to any folder in your project.[br]
##By default AraVox will look in your folder root.
@export var shorthands_override := ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
