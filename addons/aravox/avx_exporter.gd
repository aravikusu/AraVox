@tool
extends EditorExportPlugin
## This ensures that .avx files are exported as plain text files.
##
## Because .avx is registered as a custom imported Resource, Godot would
## normally remap the source file to its imported .res counterpart in an
## exported build. AraVox reads the raw script text with FileAccess, so
## that remap makes FileAccess.open(path) return null and no dialogue is
## loaded. This plugin skips the default imported export and re-adds the
## raw source file instead.


func _get_name() -> String:
	return "AraVoxExportPlugin"


func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if not path.ends_with(".avx"):
		return

	# Stop Godot from exporting this as a remapped imported Resource.
	skip()

	# Re-add the raw .avx source so AraVox can read it at runtime.
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		add_file(path, file.get_buffer(file.get_length()), false)
		file.close()
