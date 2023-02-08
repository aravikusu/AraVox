extends Control


@onready var aravox_controller = $AraVoxController
# Called when the node enters the scene tree for the first time.
func _ready():
	aravox_controller.generate()
