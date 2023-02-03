extends Control


@onready var aravox_controller = $AraVoxController
# Called when the node enters the scene tree for the first time.
func _ready():
	aravox_controller.generate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
