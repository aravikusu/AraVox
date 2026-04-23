extends Control

## The RichTextLabel that you want AraVox to plug speaker names into.
@onready var name_label: RichTextLabel = %NameLabel
## The RichTextLabel that you want AraVox to plug text into.
@onready var text_box_content: RichTextLabel = %TextBoxContent
## The AraVoxCursor node driving this textbox.
@onready var cursor: AraVoxCursor = $AraVoxCursor
## Where the choices end up going.
@onready var choicebox: PanelContainer = %ChoiceBox
## The list that gets populated with ChoiceLabels
@onready var choicelist: VBoxContainer = %ChoiceList
@onready var choice_label: PackedScene = preload("res://addons/aravox/example/components/ChoiceLabel.tscn")

var choices_are_being_made: bool = false
var choice_labels: Array[MarginContainer] = []
var choice_idx: int = 0

func food_choice(props: Array[String]) -> void:
	cursor.dialogue_data["choice"] = props[0]

func _ready() -> void:
	AraVox.register_action("food_choice", Callable(food_choice))
	
	cursor.generate()
	cursor.advance()

func _process(_delta: float) -> void:
	if choices_are_being_made:
		choicebox.show()
		choice_labels[choice_idx].active()
		if Input.is_action_just_pressed("ui_down"):
			choice_labels[choice_idx].inactive()
			choice_idx = (choice_idx + 1) % choice_labels.size()
		if Input.is_action_just_pressed("ui_up"):
			choice_labels[choice_idx].inactive()
			choice_idx = (choice_idx - 1 + choice_labels.size()) % choice_labels.size()
		if Input.is_action_just_pressed("ui_accept"):
			confirm_choice()
	else:
		choicebox.hide()
		if Input.is_action_just_pressed("ui_accept"):
			cursor.advance()

func confirm_choice() -> void:
	for label in choice_labels:
		label.queue_free()
	choice_labels.clear()
	choices_are_being_made = false
	cursor.choose(choice_idx)

func _on_ara_vox_cursor_on_line(line: AraVox.Line) -> void:
	name_label.text = "[center]" + line.speaker
	text_box_content.text = line.line

func _on_ara_vox_cursor_on_choice(choice: AraVox.Choice) -> void:
	choices_are_being_made = true
	choice_idx = 0
	for option in choice.options:
		var label: MarginContainer = choice_label.instantiate()
		choicelist.add_child(label)
		label.set_text(option)
		label.inactive()
		choice_labels.append(label)

func _on_ara_vox_cursor_on_action(action: AraVox.Action) -> void:
	action.call_action()

func _on_ara_vox_cursor_on_end() -> void:
	name_label.text = ""
	text_box_content.text = "SCRIPT END"
