@tool
@icon("res://addons/venudie/dieback_icon.svg")
class_name BattleBackground
extends Control

@export var data: DiebackData
## Wrap animation time so it repeats every loop_duration seconds.
@export var loop := false
@export_range(0.1, 600.0, 0.1, "or_greater") var loop_duration := 4.0

const BLEND_RENDER_MODES := ["blend_mix", "blend_add", "blend_sub"]

var _rects: Array[ColorRect] = []
var _blends: Array[int] = []
var _shader_src := ""
var _time := 0.0
var _drawn_bg := Color(0, 0, 0, 0)
var _drawn_size := Vector2.ZERO


func _ready() -> void:
	clip_contents = true
	_shader_src = (load("res://addons/venudie/dieback.gdshader") as Shader).code


func _draw() -> void:
	if data == null:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(data.canvas_size)), data.background_color)


func _process(delta: float) -> void:
	if data == null:
		if _drawn_size != Vector2.ZERO:
			_drawn_size = Vector2.ZERO
			queue_redraw()
		return
	var cs := Vector2(data.canvas_size)
	if data.background_color != _drawn_bg or cs != _drawn_size:
		_drawn_bg = data.background_color
		_drawn_size = cs
		queue_redraw()
	_time += delta
	var t := fposmod(_time, maxf(loop_duration, 0.01)) if loop else _time
	custom_minimum_size = Vector2(data.canvas_size)
	var n := data.layers.size()
	while _rects.size() > n:
		_rects.pop_back().queue_free()
		_blends.pop_back()
	while _rects.size() < n:
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = Color(0, 0, 0, 0)
		add_child(r)
		_rects.append(r)
		_blends.append(-1)
	for i in n:
		_update_layer(i, data.layers[i], n, t)


func _update_layer(i: int, l: DiebackLayer, n: int, t: float) -> void:
	var r := _rects[i]
	move_child(r, n - 1 - i) # layer 0 drawn last (on top)
	r.size = Vector2(data.canvas_size)
	r.visible = l.visible and l.texture != null
	if not r.visible:
		return

	if _blends[i] != l.blend_mode:
		var sh := Shader.new()
		sh.code = _shader_src.replace("//BLEND", "render_mode %s;" % BLEND_RENDER_MODES[l.blend_mode])
		var m := ShaderMaterial.new()
		m.shader = sh
		r.material = m
		_blends[i] = l.blend_mode

	var scale_safe := Vector2(maxf(absf(l.texture_scale.x), 0.01), maxf(absf(l.texture_scale.y), 0.01))
	var scaled_size := Vector2(l.texture.get_size()) * scale_safe

	var off := -l.offset * (t if l.offset_scrolling else 1.0)
	off = Vector2(fposmod(off.x, scaled_size.x), fposmod(off.y, scaled_size.y))
	var sh_off := -l.shift * (t if l.shift_scrolling else 1.0)
	sh_off = Vector2(
		fposmod(sh_off.x, maxf(absf(l.frequency.x) * 2.0, 0.0001)),
		fposmod(sh_off.y, maxf(absf(l.frequency.y) * 2.0, 0.0001)))

	var m := r.material as ShaderMaterial
	m.set_shader_parameter("layer_tex", l.texture)
	m.set_shader_parameter("canvas_size", Vector2(data.canvas_size))
	m.set_shader_parameter("tex_scale", scale_safe)
	m.set_shader_parameter("tex_offset", off)
	m.set_shader_parameter("axis_mode", Vector2i(l.mode_x, l.mode_y))
	m.set_shader_parameter("axis_frequency", l.frequency)
	m.set_shader_parameter("axis_amplitude", l.amplitude)
	m.set_shader_parameter("axis_shift", sh_off)
	m.set_shader_parameter("opacity", l.opacity)
	m.set_shader_parameter("modulate_color", l.modulate)
	m.set_shader_parameter("plane_amplitude", l.plane_amplitude)

	var use_pal := l.palette != null
	m.set_shader_parameter("palette_enabled", use_pal)
	if use_pal:
		var h := float(l.palette.get_height())
		var row := l.palette_index * (t if l.palette_cycling else 1.0)
		m.set_shader_parameter("palette_tex", l.palette)
		m.set_shader_parameter("palette_index", (floorf(fposmod(row, h)) + 0.5) / h)
