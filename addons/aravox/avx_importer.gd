@tool
extends EditorImportPlugin

const AvxFile = preload("res://addons/aravox/avx_file.gd")

func _get_importer_name() -> String:
	return "aravox.avx_importer"

func _get_visible_name() -> String:
	return "AraVox Script"

func _get_recognized_extensions() -> PackedStringArray:
	return ["avx"]

func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "Resource"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(_preset_index: int) -> String:
	return "Default"

func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []

func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, _options: Dictionary, _r_platform_variants: Array[String], _r_gen_files: Array[String]) -> Error:
	var avx_file: Resource = AvxFile.new()
	avx_file.source_path = source_file
	return ResourceSaver.save(avx_file, "%s.%s" % [save_path, _get_save_extension()])
