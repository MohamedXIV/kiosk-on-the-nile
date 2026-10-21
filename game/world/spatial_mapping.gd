class_name SpatialMapping
extends RefCounted
var x_scale: float
var depth_scale: float
var height_scale: float
func _init(config: Dictionary = {}) -> void:
 x_scale = float(config.get("x_scale",68))
 depth_scale = float(config.get("depth_scale",54))
 height_scale = float(config.get("height_scale",48))
func to_canvas(ground: Vector2, height: float = 0.0) -> Vector2:
 return Vector2(ground.x*x_scale,ground.y*depth_scale-height*height_scale)
func to_ground(canvas: Vector2) -> Vector2:
 return Vector2(canvas.x/x_scale,canvas.y/depth_scale)
