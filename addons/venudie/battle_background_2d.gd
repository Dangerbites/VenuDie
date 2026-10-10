@tool
@icon("res://addons/venudie/dieback_icon.svg")
class_name BattleBackground2D
extends Sprite2D

@export var data: DiebackData:
	set(v):
		data = v
		_apply()
@export var loop := false:
	set(v):
		loop = v
		_apply()
@export_range(0.1, 600.0, 0.1, "or_greater") var loop_duration := 4.0:
	set(v):
		loop_duration = v
		_apply()

var _vp: SubViewport
var _bg: BattleBackground


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vp = SubViewport.new()
	_vp.size = Vector2i(320, 180)
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_vp, false, Node.INTERNAL_MODE_FRONT)
	_bg = BattleBackground.new()
	_vp.add_child(_bg)
	_apply()
	texture = _vp.get_texture()


func _process(_delta: float) -> void:
	if _vp and data:
		var s := Vector2i(maxi(data.canvas_size.x, 1), maxi(data.canvas_size.y, 1))
		if _vp.size != s:
			_vp.size = s


func _apply() -> void:
	if _bg == null:
		return
	_bg.data = data
	_bg.loop = loop
	_bg.loop_duration = loop_duration
