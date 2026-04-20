@tool
extends VBoxContainer


@onready var code_edit: CodeEdit = $CodeEdit
@onready var file_path_label: Label = %FilePath
@onready var debounce: Timer = $Debounce
@onready var open_button: Button = %OpenButton
@onready var new_button: Button = %NewButton
@onready var wiki_button: Button = %WikiButton
@onready var insert_button: OptionButton = %InsertButton
@onready var comment_button: Button = %CommentButton
@onready var toolbox: PanelContainer = %Toolbox


var load_dialog: EditorFileDialog
var new_dialog: EditorFileDialog

var open_file_path: String = ""

func _ready() -> void:
	## UI CODE SPEW, GO!!
	new_button.icon = EditorInterface.get_editor_theme().get_icon("New", "EditorIcons")
	open_button.icon = EditorInterface.get_editor_theme().get_icon("Load", "EditorIcons")
	wiki_button.icon = EditorInterface.get_editor_theme().get_icon("ExternalLink", "EditorIcons")
	comment_button.icon = EditorInterface.get_editor_theme().get_icon("VisualShaderNodeComment", "EditorIcons")

	load_dialog = EditorFileDialog.new()
	load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	load_dialog.add_filter("*.avx", "AraVox Script")
	load_dialog.title = "Open AraVox script"
	load_dialog.file_selected.connect(_on_load_file_selected)
	add_child(load_dialog)
	
	new_dialog = EditorFileDialog.new()
	new_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	new_dialog.add_filter("*.avx", "AraVox Script")
	new_dialog.ok_button_text = "Create"
	new_dialog.title = "Create new AraVox script"
	new_dialog.file_selected.connect(_on_new_file_selected)
	add_child(new_dialog)
	
	# We wanna be able to drag a file onto the editor to instantly have it appear,
	# not just on the "toolbar" above it. So...
	code_edit.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)

	insert_button.clear()
	insert_button.add_item("Insert...")
	insert_button.add_separator("Functions")
	insert_button.add_item("#rand", 2)
	insert_button.add_item("#pl", 3)
	insert_button.add_item("#action", 4)
	insert_button.add_separator("Blocks")
	insert_button.add_item("#if", 6)
	insert_button.add_item("#if-else", 7)
	insert_button.add_item("#choice", 8)
	insert_button.add_separator("Other")
	insert_button.add_item("[Speaker]", 10)
	insert_button.add_item("{{&data}}", 11)
	insert_button.add_item("{{%shorthand}}", 12)

func _process(_delta: float) -> void:
	if open_file_path == "":
		code_edit.text = "Use the toolbar above to either create or open an AraVox Script.\nYou can also double-click an .avx file in the FileSystem, or drag-and-drop it in."
		code_edit.editable = false
		code_edit.mouse_default_cursor_shape = Control.CURSOR_ARROW
		code_edit.gutters_draw_line_numbers = false
		toolbox.visible = false
	else:
		code_edit.editable = true
		code_edit.mouse_default_cursor_shape = Control.CURSOR_IBEAM
		code_edit.gutters_draw_line_numbers = true
		toolbox.visible = true

func open_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	code_edit.text = file.get_as_text()
	file.close()
	open_file_path = path
	file_path_label.text = path.get_file()

func _on_load_file_selected(path: String) -> void:
	open_file(path)

func contains_avx(f: String) -> bool:
	return f.ends_with(".avx")

func _can_drop_data(_at_pos: Vector2, data: Variant) -> bool:
	if data is Dictionary && data.has("files"):
		return (data["files"] as Array).any(contains_avx)
	return false

func _drop_data(_at_pos: Vector2, data: Variant) -> void:
	for path: String in data["files"]:
		if path.ends_with(".avx"):
			open_file(path)
			break

func _on_new_file_selected(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("# You can now start scripting! If you need help, press the Wiki button in the toolbar.")
	file.close()
	_on_load_file_selected(path)

func _on_open_button_pressed() -> void:
	load_dialog.popup_file_dialog()

func _on_code_edit_text_changed() -> void:
	debounce.start()

func _on_timer_timeout() -> void:
	if !open_file_path:
		return
	
	var file: FileAccess = FileAccess.open(open_file_path, FileAccess.WRITE)
	file.store_string(code_edit.text)
	file.close()
	print("AraVox Editor: %s was saved." % open_file_path.get_file())


func _on_new_button_pressed() -> void:
	new_dialog.popup_file_dialog()


func _on_wiki_button_pressed() -> void:
	OS.shell_open("https://github.com/aravikusu/AraVox/wiki")

## Contains all the presets to insert (yes, I am aware that this index stuff is dreadful)
func _on_insert_button_item_selected(index: int) -> void:
	# first, set back to 0 (so ui goes back to "Insert..."
	insert_button.selected = 0
	code_edit.grab_focus()
	
	var line: String = code_edit.get_line(code_edit.get_caret_line())
	var is_line_empty: bool = line.strip_edges() == ""
	
	match index:
		2: code_edit.insert_text_at_caret("{{#rand One, Of, These}}")
		3: code_edit.insert_text_at_caret("{{#pl $probably_data, singular, plural}}")
		4:
			code_edit.insert_text_at_caret("%s{{#action registered_name, comma, separated, data}}" % ["" if is_line_empty else "\n"])
		6:
			code_edit.insert_text_at_caret("%s{{#if $some_data, >, 5}}" % ["" if is_line_empty else "\n"])
			code_edit.insert_text_at_caret("\n# Your text goes here...")
			code_edit.insert_text_at_caret("\n{{/if}}")
		7:
			code_edit.insert_text_at_caret("%s{{#if $some_data, ==, 5}}" % ["" if is_line_empty else "\n"])
			code_edit.insert_text_at_caret("\n# Your text goes here...")
			code_edit.insert_text_at_caret("\n{{#else}}")
			code_edit.insert_text_at_caret("\n# Your text goes here...")
			code_edit.insert_text_at_caret("\n{{/if}}")
		8:
			code_edit.insert_text_at_caret("%s{{#choice A choice, Another choice}}" % ["" if is_line_empty else "\n"])
			code_edit.insert_text_at_caret("\n{{#branch}}")
			code_edit.insert_text_at_caret("\n# Do you want the red pill...")
			code_edit.insert_text_at_caret("\n{{/branch}}")
			code_edit.insert_text_at_caret("\n{{#branch}}")
			code_edit.insert_text_at_caret("\n# ... or the blue one?")
			code_edit.insert_text_at_caret("\n{{/branch}}")
			code_edit.insert_text_at_caret("\n{{/choice}}")
		10: code_edit.insert_text_at_caret("%s[Speaker] I'm making a note here: huge success." % ["" if is_line_empty else "\n"])
		11: code_edit.insert_text_at_caret("{{$placeholder_data}}")
		12: code_edit.insert_text_at_caret("{{%placeholder_shorthand}}")


func _on_comment_button_pressed() -> void:
	var from_line: int
	var to_line: int

	if code_edit.has_selection():
		from_line = code_edit.get_selection_from_line()
		to_line = code_edit.get_selection_to_line()
		if code_edit.get_selection_to_column() == 0:
			to_line -= 1
	else:
		# If we don't have anything selected we just get the one the caret is on
		from_line = code_edit.get_caret_line()
		to_line = from_line

	var comments: int = 0
	for i in range(from_line, to_line + 1):
		if code_edit.get_line(i).begins_with("#"):
			comments += 1

	var total: int = to_line - from_line + 1
	for i in range(from_line, to_line + 1):
		var line: String = code_edit.get_line(i)
		if comments < total:
			# If not all lines are comments, we comment everything
			if !line.begins_with("#"):
				code_edit.set_line(i, "#" + line)
		else:
			# If all lines are comments, we uncomment everything
			if line.begins_with("#"):
				code_edit.set_line(i, line.substr(1))
