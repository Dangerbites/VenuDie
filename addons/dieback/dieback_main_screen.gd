@tool
extends VBoxContainer

const LOGO_PATH := "res://addons/dieback/dieback_icon.svg"
const LOGO_SCALE := 9.0
const URL_AUTHOR := "https://nicenibbles.com/anteger-dev"
const URL_ORIGINAL := "https://github.com/Okanoa/Dieback"

var data := DiebackData.new()
var save_path := ""

var _bg: BattleBackground
var _svc: SubViewportContainer
var _tree: Tree
var _inspector: EditorInspector
var _dialog: EditorFileDialog
var _w: SpinBox
var _h: SpinBox
var _bg_color: ColorPickerButton
var _saving := false
var _home: Control
var _editor: Control


func _ready() -> void:
	DiebackFormat.register()
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_build_home()

	# Everything below is the editor, hidden until a project is opened
	_editor = VBoxContainer.new()
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_editor)

	# Toolbar
	var bar := HBoxContainer.new()
	_editor.add_child(bar)
	_add_button(bar, "New", _on_new)
	_add_button(bar, "Open", _on_open)
	_add_button(bar, "Save", _on_save)
	_add_button(bar, "Close", _show_home)
	bar.add_child(VSeparator.new())
	_add_button(bar, "Add Layer", _on_add_layer)
	_add_button(bar, "Remove Layer", _on_remove_layer)
	_add_button(bar, "Move Up", func(): _move_layer(-1))
	_add_button(bar, "Move Down", func(): _move_layer(1))
	bar.add_child(VSeparator.new())
	var res_label := Label.new()
	res_label.text = "Resolution"
	bar.add_child(res_label)
	_w = _make_spin(bar, data.canvas_size.x)
	var x_label := Label.new()
	x_label.text = "x"
	bar.add_child(x_label)
	_h = _make_spin(bar, data.canvas_size.y)
	bar.add_child(VSeparator.new())
	var bg_label := Label.new()
	bg_label.text = "Background"
	bar.add_child(bg_label)
	_bg_color = ColorPickerButton.new()
	_bg_color.edit_alpha = true
	_bg_color.color = data.background_color
	_bg_color.custom_minimum_size = Vector2(48, 0) * EditorInterface.get_editor_scale()
	_bg_color.color_changed.connect(_on_bg_color_changed)
	bar.add_child(_bg_color)

	# Body: [layers + inspector] | preview
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.add_child(split)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 340
	split.add_child(left)

	_tree = Tree.new()
	_tree.custom_minimum_size.y = 180 * EditorInterface.get_editor_scale()
	_tree.hide_root = true
	_tree.select_mode = Tree.SELECT_ROW
	_tree.columns = 2
	_tree.set_column_expand(0, false)
	_tree.set_column_custom_minimum_width(0, int(30 * EditorInterface.get_editor_scale()))
	_tree.set_column_expand(1, true)
	_tree.item_selected.connect(func(): _on_layer_selected(_selected()))
	_tree.button_clicked.connect(_on_tree_button_clicked)
	left.add_child(_tree)

	_inspector = EditorInspector.new()
	_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector.property_edited.connect(_on_inspector_property_edited)
	left.add_child(_inspector)

	var preview_box := CenterContainer.new()
	preview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(preview_box)

	_svc = SubViewportContainer.new()
	_svc.stretch = true
	_svc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_box.add_child(_svc)

	var vp := SubViewport.new()
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_svc.add_child(vp)

	_bg = BattleBackground.new()
	_bg.data = data
	vp.add_child(_bg)

	_dialog = EditorFileDialog.new()
	_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_dialog.file_selected.connect(_on_file_selected)
	add_child(_dialog)

	_update_preview()
	_refresh_list()
	_show_home()


## Home screen shown when no project is open: logo, credits, then buttons, all centered.
func _build_home() -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(center)
	_home = center

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var logo := TextureRect.new()
	var tex := _load_logo()
	if tex:
		logo.texture = tex
		logo.custom_minimum_size = tex.get_size()
	logo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(logo)

	var title := Label.new()
	title.text = "VenuDie - Dieback Godot Port"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(32 * EditorInterface.get_editor_scale()))
	box.add_child(title)

	var credits := RichTextLabel.new()
	credits.bbcode_enabled = true
	credits.fit_content = true
	credits.scroll_active = false
	credits.custom_minimum_size.x = 420 * EditorInterface.get_editor_scale()
	credits.text = "[center]Made by [url=%s]Anteger[/url]\nBased on [url=%s]Dieback[/url] by Okanoa[/center]" % [URL_AUTHOR, URL_ORIGINAL]
	credits.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	box.add_child(credits)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var new_btn := _add_button(buttons, "New", _on_new)
	var open_btn := _add_button(buttons, "Open", _on_open)
	for b in [new_btn, open_btn]:
		b.custom_minimum_size = Vector2(110, 36) * EditorInterface.get_editor_scale()


func _load_logo() -> Texture2D:
	var svg := FileAccess.get_file_as_string(LOGO_PATH)
	if not svg.is_empty():
		var img := Image.new()
		if img.load_svg_from_string(svg, LOGO_SCALE * EditorInterface.get_editor_scale()) == OK:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(LOGO_PATH):
		return load(LOGO_PATH)
	return null


func _show_home() -> void:
	_home.visible = true
	_editor.visible = false


func _show_editor() -> void:
	_home.visible = false
	_editor.visible = true


func _make_spin(parent: Node, value: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = 8
	s.max_value = 4096
	s.step = 1
	s.value = value
	s.value_changed.connect(_on_res_changed)
	parent.add_child(s)
	return s


func _add_button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _on_bg_color_changed(c: Color) -> void:
	data.background_color = c


func _on_res_changed(_v: float) -> void:
	data.canvas_size = Vector2i(int(_w.value), int(_h.value))
	_update_preview()


## Shows the canvas at the largest whole-number zoom that fits roughly 960x540.
func _update_preview() -> void:
	var c := data.canvas_size
	var zoom := maxi(1, mini(int(960.0 / maxf(c.x, 1.0)), int(540.0 / maxf(c.y, 1.0))))
	_svc.stretch_shrink = zoom
	_svc.custom_minimum_size = Vector2(c * zoom)


func _sync_res_boxes() -> void:
	_w.set_value_no_signal(data.canvas_size.x)
	_h.set_value_no_signal(data.canvas_size.y)
	_bg_color.color = data.background_color


func _refresh_list(select := -1) -> void:
	_tree.clear()
	var root := _tree.create_item()
	for l in data.layers:
		_update_row(root.create_child(), l)
	if select >= 0 and select < data.layers.size():
		root.get_child(select).select(1)
		_on_layer_selected(select)
	else:
		_inspector.edit(null)


## Refreshes one row: eye button, texture thumbnail and title.
func _update_row(item: TreeItem, l: DiebackLayer) -> void:
	var et := EditorInterface.get_editor_theme()
	var eye := et.get_icon("GuiVisibilityVisible" if l.visible else "GuiVisibilityHidden", "EditorIcons")
	if item.get_button_count(0) == 0:
		item.add_button(0, eye, 0, false, "Toggle visibility")
	else:
		item.set_button(0, 0, eye)
	item.set_text(1, l.title)
	item.set_icon(1, l.texture)
	item.set_icon_max_width(1, int(40 * EditorInterface.get_editor_scale()))
	var dim := Color(1, 1, 1, 1.0 if l.visible else 0.4)
	item.set_icon_modulate(1, dim)
	item.set_custom_color(1, Color(1, 1, 1, 1.0 if l.visible else 0.45))


func _on_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button: int) -> void:
	var i := item.get_index()
	if i < 0 or i >= data.layers.size():
		return
	data.layers[i].visible = not data.layers[i].visible
	_update_row(item, data.layers[i])
	if _selected() == i:
		_inspector.refresh()


func _on_inspector_property_edited(_property: String) -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	var i := item.get_index()
	if i >= 0 and i < data.layers.size():
		_update_row(item, data.layers[i])


func _on_layer_selected(i: int) -> void:
	if i < 0 or i >= data.layers.size():
		return
	_inspector.edit(data.layers[i])


func _selected() -> int:
	var item := _tree.get_selected()
	return item.get_index() if item != null else -1


func _on_add_layer() -> void:
	var l := DiebackLayer.new()
	l.title = "Layer%d" % (data.layers.size() + 1)
	data.layers.append(l)
	_refresh_list(data.layers.size() - 1)


func _on_remove_layer() -> void:
	var i := _selected()
	if i < 0:
		return
	data.layers.remove_at(i)
	_refresh_list(mini(i, data.layers.size() - 1))


func _move_layer(dir: int) -> void:
	var i := _selected()
	var j := i + dir
	if i < 0 or j < 0 or j >= data.layers.size():
		return
	var l := data.layers[i]
	data.layers.remove_at(i)
	data.layers.insert(j, l)
	_refresh_list(j)


func _on_new() -> void:
	data.layers.clear()
	save_path = ""
	_refresh_list()
	_show_editor()


func _on_open() -> void:
	_saving = false
	_dialog.clear_filters()
	_dialog.add_filter("*.dieback, *.tres", "Dieback background")
	_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_dialog.popup_file_dialog()


func _on_save() -> void:
	if save_path.get_extension() == "dieback":
		_write(save_path)
		return
	_saving = true
	_dialog.clear_filters()
	_dialog.add_filter("*.dieback", "Dieback background")
	_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_dialog.popup_file_dialog()


func _write(path: String) -> void:
	var err := DiebackFormat.save_file(data, path)
	if err != OK:
		push_error("Dieback: failed to save %s (%s)" % [path, error_string(err)])
		return
	EditorInterface.get_resource_filesystem().scan()


func _on_file_selected(path: String) -> void:
	if _saving:
		if path.get_extension() != "dieback":
			path = path.get_basename() + ".dieback"
		save_path = path
		_write(path)
	else:
		var loaded := DiebackFormat.load_file(path)
		if loaded == null:
			push_error("Dieback: could not open %s" % path)
			return
		data = loaded
		_bg.data = data
		save_path = path
		_sync_res_boxes()
		_update_preview()
		_refresh_list(0 if data.layers.size() > 0 else -1)
		_show_editor()