class_name WarmLight
extends Sprite2D
func configure(data: Dictionary) -> void:
 var gradient := Gradient.new()
 var color := Color(data.color)
 gradient.colors = PackedColorArray([Color(color,0.30*float(data.energy)),Color(color,0)])
 var radial := GradientTexture2D.new()
 radial.gradient = gradient
 radial.fill = GradientTexture2D.FILL_RADIAL
 radial.fill_from = Vector2(0.5,0.5)
 radial.fill_to = Vector2(1,0.5)
 radial.width = 256
 radial.height = 256
 texture = radial
 scale = Vector2.ONE*float(data.radius)*2/256.0
 var blend := CanvasItemMaterial.new()
 blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
 material = blend
 z_index = -20
