@tool
class_name DiebackLayer
extends Resource

enum BlendMode { ALPHA, ADD, SUBTRACT }
enum AxisMode { OSCILLATION, INTERLACED, COMPRESSION, LINEAR_SCALING }

@export var title := "Layer"
@export var visible := true

@export_group("Texture")
@export var texture: Texture2D
## Size multiplier for the texture. 2 = twice as big, 0.5 = half size.
@export var texture_scale := Vector2.ONE

@export_group("Blend")
@export var blend_mode: BlendMode = BlendMode.ALPHA
@export_range(0.0, 1.0, 0.01) var opacity := 1.0
## Tints the layer. Multiplies the layer's colour and alpha. White = no change.
@export var modulate := Color.WHITE

@export_group("Offset")
@export var offset_scrolling := false
## In screen pixels. When scrolling, this is pixels per second.
@export var offset := Vector2.ZERO

@export_group("Axis Distortion")
@export var mode_x: AxisMode = AxisMode.OSCILLATION
@export var mode_y: AxisMode = AxisMode.OSCILLATION
## Wave length control. Higher = wider waves. A value of 1 produces no visible wave.
@export var frequency := Vector2(16, 16)
## Distortion strength in pixels.
@export var amplitude := Vector2(8, 8)
@export var shift_scrolling := false
@export var shift := Vector2.ZERO

@export_group("Palette")
@export var palette: Texture2D
@export var palette_cycling := false
@export var palette_index := 0.0

@export_group("Plane Distortion")
## Fisheye strength. Positive = fisheye, negative = anti-fisheye.
@export_range(-1.0, 1.0, 0.01) var plane_amplitude := 0.0
