@tool
class_name DiebackFormat
extends RefCounted

static var _saver: ResourceFormatSaver
static var _loader: ResourceFormatLoader


static func register() -> void:
	unregister()
	_saver = Saver.new()
	_loader = Loader.new()
	ResourceSaver.add_resource_format_saver(_saver)
	ResourceLoader.add_resource_format_loader(_loader)


static func unregister() -> void:
	if _saver != null:
		ResourceSaver.remove_resource_format_saver(_saver)
		_saver = null
	if _loader != null:
		ResourceLoader.remove_resource_format_loader(_loader)
		_loader = null


## Saves a .dieback (or any other) resource without needing the saver to be registered.
static func save_file(res: Resource, path: String) -> Error:
	if path.get_extension().to_lower() != "dieback":
		return ResourceSaver.save(res, path)
	var tmp := "user://_dieback_save.tres"
	var err := ResourceSaver.save(res, tmp)
	if err != OK:
		return err
	var text := FileAccess.get_file_as_string(tmp)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	return OK


## Loads a .dieback (or .tres) file without needing the loader to be registered.
static func load_file(path: String) -> DiebackData:
	if path.get_extension().to_lower() != "dieback":
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as DiebackData
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return null
	var tmp := "user://_dieback_open_%s.tres" % path.md5_text()
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return null
	f.store_string(text)
	f.close()
	var res := ResourceLoader.load(tmp, "", ResourceLoader.CACHE_MODE_IGNORE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	return res as DiebackData


class Saver extends ResourceFormatSaver:
	func _get_recognized_extensions(_resource: Resource) -> PackedStringArray:
		return PackedStringArray(["dieback"])

	func _recognize(resource: Resource) -> bool:
		return resource is DiebackData

	func _save(resource: Resource, path: String, _flags: int) -> Error:
		return DiebackFormat.save_file(resource, path)


class Loader extends ResourceFormatLoader:
	func _get_recognized_extensions() -> PackedStringArray:
		return PackedStringArray(["dieback"])

	func _recognize_path(path: String, _type: StringName) -> bool:
		return path.get_extension().to_lower() == "dieback"

	func _handles_type(type: StringName) -> bool:
		return type == &"Resource" or type == &"DiebackData"

	func _get_resource_type(path: String) -> String:
		return "Resource" if path.get_extension().to_lower() == "dieback" else ""

	func _get_resource_script_class(path: String) -> String:
		return "DiebackData" if path.get_extension().to_lower() == "dieback" else ""

	func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
		var res := DiebackFormat.load_file(path)
		if res == null:
			return ERR_PARSE_ERROR
		return res