## This simply ensures that .avx files are automatically exported
## when you export your game.
##
## This more or less means you won't have to manually add .avx files
## to your export settings. Wee.
@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "AraVoxExportPlugin"

func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_add_avx_files("res://")

func _add_avx_files(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_add_avx_files(dir_path.path_join(entry))
		elif entry.ends_with(".avx"):
			var full_path: String = dir_path.path_join(entry)
			var file: FileAccess = FileAccess.open(full_path, FileAccess.READ)
			if file:
				add_file(full_path, file.get_buffer(file.get_length()), false)
				file.close()
		entry = dir.get_next()
	dir.list_dir_end()
