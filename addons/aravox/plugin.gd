@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	add_autoload_singleton("AraVox", "res://addons/aravox/aravox.gd")
	add_custom_type("AraVoxController", "Control", preload("res://addons/aravox/scripts/aravox_controller.gd"), preload("res://addons/aravox/assets/icon.png"))
	add_custom_type("AraVoxConfig", "Resource", preload("res://addons/aravox/scripts/aravox_config.gd"), preload("res://addons/aravox/assets/icon.png"))

func _exit_tree():
	remove_autoload_singleton("AraVox")
	remove_custom_type("AraVoxController")
	remove_custom_type("AraVoxConfig")
