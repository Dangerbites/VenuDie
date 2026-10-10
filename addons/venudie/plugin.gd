@tool
extends EditorPlugin

const MainScreen := preload("res://addons/venudie/dieback_main_screen.gd")
const ICON := "res://addons/venudie/dieback_icon.svg"
const AUTOLOAD := "DiebackRuntime"

var main_screen: Control


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD, "res://addons/venudie/dieback_runtime.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD)


func _enter_tree() -> void:
	DiebackFormat.register()
	print("Dieback: .dieback loader active = ", ResourceLoader.get_recognized_extensions_for_type("Resource").has("dieback"))
	main_screen = MainScreen.new()
	main_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(main_screen)
	_make_visible(false)


func _exit_tree() -> void:
	if main_screen:
		main_screen.queue_free()
	DiebackFormat.unregister()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if main_screen:
		main_screen.visible = visible


func _get_plugin_name() -> String:
	return "Dieback"


func _get_plugin_icon() -> Texture2D:
	if ResourceLoader.exists(ICON):
		return load(ICON)
	return EditorInterface.get_editor_theme().get_icon("Environment", "EditorIcons")
