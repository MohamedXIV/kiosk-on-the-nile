class_name FatigueOverlay
extends ColorRect
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 material=ShaderMaterial.new()
 material.shader=load("res://assets/shaders/fatigue_blur.gdshader")
 hide()
func present(view: Dictionary) -> void:
 var strength := clampf(float(view.get("strength",0)),0,1)
 visible=strength>0.001
 material.set_shader_parameter("strength",strength)
