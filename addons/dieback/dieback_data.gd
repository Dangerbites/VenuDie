@tool
@icon("res://addons/dieback/dieback_icon.svg")
class_name DiebackData
extends Resource

## Index 0 is the top layer.
@export var layers: Array[DiebackLayer] = []
## Render resolution. Used by the editor preview and all BattleBackground nodes.
@export var canvas_size := Vector2i(320, 180)
## Drawn behind all layers. Leave fully transparent for no background.
@export var background_color := Color(0, 0, 0, 0)
