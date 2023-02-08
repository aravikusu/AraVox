extends MarginContainer

@onready var panel = $PanelContainer
@onready var label = $"%Label"
func set_text(text):
	label.text = text

func active():
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#1a1a1a")
	panel.add_theme_stylebox_override("panel", stylebox)

func inactive():
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#1a1a1a00")
	panel.add_theme_stylebox_override("panel", stylebox)
