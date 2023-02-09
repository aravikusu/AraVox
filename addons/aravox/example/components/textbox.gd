extends MarginContainer

## The RichTextLabel that you want AraVox to plug speaker names into.
@export var name_label : RichTextLabel
## The RichTextLabel that you want AraVox to plug text into.
@export var text_box_content : RichTextLabel

var dialogue_script = []
var dialogue_choices = []
var current_line := -1

var choices_are_being_made = false
var current_choice = {}
var choice_labels = []
var choice_idx = 0

var currently_in_branch = -1
var branch_length = 0
var current_line_in_branch = 0

var start = false

@onready var choicebox = $"%ChoiceBox"
@onready var choicelist = $"%ChoiceList"
@onready var choice_label = preload("res://addons/aravox/example/components/ChoiceLabel.tscn")

func handle_inputs() -> void:
	if choices_are_being_made:
		if Input.is_action_just_pressed("ui_down"):
			choice_labels[choice_idx].inactive()
			if choice_idx + 1 >= choice_labels.size():
				choice_idx = 0
			else:
				choice_idx += 1
		if Input.is_action_just_pressed("ui_up"):
			choice_labels[choice_idx].inactive()
			if choice_idx - 1 < 0:
				choice_idx = choice_labels.size() - 1
			else:
				choice_idx -= 1
		
		if Input.is_action_just_pressed("ui_accept"):
			make_choice()
	else:
		if Input.is_action_just_pressed("ui_accept"):
			advance_line()

func _process(_delta):
	if start:
		handle_inputs()
	
	if choices_are_being_made:
		choicebox.show()
		choice_labels[choice_idx].active()
	else:
		choicebox.hide()

func advance_line():
	current_line += 1
	
	if current_line_in_branch < branch_length:
		current_line_in_branch += 1
	
	if current_line < dialogue_script.size():
		var line = dialogue_script[current_line]
		var split = line.split(":")
		name_label.text = "[center]" + split[0]
		text_box_content.text = split[1]
		check_choices()
	else:
		name_label.text = ""
		text_box_content.text = "SCRIPT END"
	
	if current_line_in_branch == branch_length:
		current_line_in_branch = 0
		branch_length = 0
		currently_in_branch = -1

func check_choices():
	if dialogue_choices.size() > 0:
		for choice in dialogue_choices:
			if choice.appears_on == current_line + 1:
				var go = true
				if currently_in_branch != -1:
					if currently_in_branch != choice.appears_in_branch:
						go = false
				
				if go:
					choices_are_being_made = true
					current_choice = choice
					fill_choices()

func fill_choices():
	for choice in current_choice.options:
		var new_label = choice_label.instantiate()
		choicelist.add_child(new_label)
		new_label.set_text(choice)
		new_label.inactive()
		
		choice_labels.append(new_label)

func make_choice():
	if choice_idx < current_choice.branches.size():
		var chosen = current_choice.branches[choice_idx]
		dialogue_script.append_array(chosen)
		currently_in_branch = choice_idx
		branch_length = chosen.size()
	
	choices_are_being_made = false
	current_choice = {}
	advance_line()

func _on_ara_vox_controller_script_generation_finished(script):
	dialogue_script = script.script
	dialogue_choices = script.choices
	start = true
	advance_line()
