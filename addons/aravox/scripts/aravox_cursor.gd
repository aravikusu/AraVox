## AraVoxCursor
##
## Generates and holds your hand in actually creating a UI for AraVox scripts.
## Simply connect your file, data, and config and let the cursor signal what your UI should do next.
class_name AraVoxCursor extends Node

## A new line has appeared! It's just a normal dialogue line.
signal on_line(line: AraVox.Line)
## A choice! What will the player do?[br]
## This signal alerts you that the player has to take action.
## When they do, call the choose() function with their choice.
signal on_choice(choice: AraVox.Choice)
## An action. A function call, effectively. This signal
## returns the action your script requested to call here.
## It's up to you to handle it whichever way you see fit.
signal on_action(action: AraVox.Action)
## Show's over, folks. The script is completely done.
signal on_end

## The dialogue script file to load.
@export_file("*.avx") var dialogue_file: String = ""
## Data dictionary passed to the script for variable substitution.
@export var dialogue_data: Dictionary = {}
## Override the config file location. Defaults to res://aravox_config.tres.
@export var config_override: String = ""

## The script stack. Every block of the script will be thrown in here in order.
## The script is always reading from the "most recent" block within.
## This means that when a choice or conditional branches the script, the branch goes first,
## then when it ends we pop back in the older branch!
var _script: Array = []
var _current_choice: AraVox.Choice = null

## Generate the script. This is the starting point when you want to use AraVoxCursor.
func generate() -> void:
	assert(dialogue_file != "", "AraVox: You must supply a dialogue file before calling generate().")
	_script = [_new_block(AraVox.generate(dialogue_file, dialogue_data, config_override))]
	_current_choice = null

## Progresses the script.
func advance() -> void:
	if _current_choice != null:
		return

	# If there are still blocks in the script, and the most recent one is past its size, we get rid of it.
	# effectively gets us back to the older block (or ends the script, whichever happens.)
	while _script.size() > 0 && _script.back().position >= _script.back().content.size():
		_script.pop_back()

	# That's all, folks
	if _script.is_empty():
		on_end.emit()
		return

	# Get the most recent block...
	var block: Dictionary = _script.back()
	# Grab the current element within it, then increment position
	var element = block.content[block.position]
	block.position += 1

	# What the heck is this element? Send the right signal.
	if element is AraVox.Line:
		on_line.emit(element)
	elif element is AraVox.Choice:
		# A choice has to be made here. Save the element, then signal up.
		# Now the user has to handle the choice and call choose()
		_current_choice = element
		on_choice.emit(element)
	elif element is AraVox.Action:
		# An Action simply signals up and advances.
		on_action.emit(element)
		advance()
	elif element is AraVox.Conditional:
		# Conditionals have to be avaluated before we advance
		var is_truthy: bool = _evaluate_condition(element)
		var content: Array
		var block_index: int
		if is_truthy:
			content = element.if_block
			block_index = 0
		else:
			content = element.else_block
			block_index = 1
		if content.size() > 0:
			_script.push_back(_new_block(content, block_index))
		advance()

## When AraVoxCursor encounters a Choice, you're alerted by the on_choice signal.
## When the player finally makes their choice, call this function with the index of the choice
## and AraVoxCursor will progress the script as intended.
func choose(index: int) -> void:
	assert(_current_choice != null, "AraVox: choose() called but no choice is pending.")
	assert(index >= 0 && index < _current_choice.branches.size(), "AraVox: Choice index out of range.")
	var content: Array = _current_choice.branches[index]
	_current_choice = null
	_script.push_back(_new_block(content, index))
	advance()

## Returns a Dictionary of the current block you're in, as well as whichever branch you're in
func save_state() -> Dictionary:
	var blocks: Array = []
	for block: Dictionary in _script:
		blocks.append({
			"position": block.position,
			"branch_index": block.get("branch_index", -1)
		})
	return {"blocks": blocks, "pending_choice": _current_choice != null}

## Restoring from a save... a bit messy
func load_state(state: Dictionary) -> void:
	generate()
	var saved: Array = state.get("blocks", [])
	if saved.is_empty():
		return

	# Retrieve the old position...
	_script[0].position = saved[0].position

	# And now we rebuild states based on the blocks we saved
	var content: Array = _script[0].content
	for i in range(1, saved.size()):
		var element = content[saved[i - 1].position - 1]
		var branch_idx: int = saved[i].branch_index
		var branch_content: Array = []
		if element is AraVox.Choice:
			branch_content = element.branches[branch_idx]
		elif element is AraVox.Conditional:
			if branch_idx == 0:
				branch_content = element.if_block
			else:
				branch_content = element.else_block
		var block: Dictionary = _new_block(branch_content, branch_idx)
		block.position = saved[i].position
		_script.push_back(block)
		content = branch_content

	if state.get("pending_choice", false):
		var block: Dictionary = _script.back()
		var element = block.content[block.position - 1]
		if element is AraVox.Choice:
			_current_choice = element
			on_choice.emit(element)

## Did the user talk to that one NPC 15 times before talking to this one to trigger the thing?
## No, I'm not jaded by old RPG's at all
func _evaluate_condition(conditional: AraVox.Conditional) -> bool:
	var vars: Array[String] = conditional.condition_vars
	var value1: String
	if vars[0].begins_with("$"):
		value1 = str(dialogue_data.get(vars[0].replace("$", ""), vars[0]))
	else:
		value1 = vars[0]

	## A simple if. example: {{#if $cool_data}}
	if vars.size() == 1:
		return bool(int(value1))

	## If we're here it's an actual evaluation
	var value2: String
	if vars[2].begins_with("$"):
		value2 = str(dialogue_data.get(vars[2].replace("$", ""), vars[2]))
	else:
		value2 = vars[2]

	match vars[1]:
		"==": return value1 == value2
		"!=": return value1 != value2
		">": return float(value1) > float(value2)
		"<": return float(value1) < float(value2)
	return false

## Get the next block. Called at the initial generation, during a new branch, conditional...
## Essentially: this is the next block you will traverse in the script.
func _new_block(content: Array, branch_index: int = -1) -> Dictionary:
	return {
		"content": content,
		"position": 0,
		"branch_index": branch_index
	}
