@tool
extends EditorPlugin

const AraVoxEditor: PackedScene = preload("res://addons/aravox/editor/aravox_editor.tscn")

const AvxFile = preload("res://addons/aravox/avx_file.gd")

var dock: EditorDock
var editor_instance: VBoxContainer
var avx_exporter: EditorExportPlugin
var avx_importer: EditorImportPlugin

func _enter_tree() -> void:
	add_autoload_singleton("AraVox", "res://addons/aravox/aravox.gd")
	add_custom_type("AraVoxCursor", "Node", preload("res://addons/aravox/scripts/aravox_cursor.gd"), preload("res://addons/aravox/assets/icon.svg"))
	add_custom_type("AraVoxConfig", "Resource", preload("res://addons/aravox/scripts/aravox_config.gd"), preload("res://addons/aravox/assets/icon.svg"))

	avx_exporter = preload("res://addons/aravox/avx_exporter.gd").new()
	add_export_plugin(avx_exporter)

	avx_importer = preload("res://addons/aravox/avx_importer.gd").new()
	add_import_plugin(avx_importer)
	
	# editor stuff
	editor_instance = AraVoxEditor.instantiate()
	
	dock = EditorDock.new()
	dock.add_child(editor_instance)
	dock.title = "AraVox Editor"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING

	add_dock(dock)

func _exit_tree() -> void:
	remove_autoload_singleton("AraVox")
	remove_custom_type("AraVoxCursor")
	remove_custom_type("AraVoxConfig")
	remove_export_plugin(avx_exporter)
	remove_import_plugin(avx_importer)

	if dock:
		remove_dock(dock)
		dock.queue_free()

func _handles(object: Object) -> bool:
	return object is Resource and object.get_script() == AvxFile

func _edit(object: Object) -> void:
	editor_instance.open_file((object as Resource).get("source_path"))
	dock.make_visible()

func _has_main_screen() -> bool:
	return false
