class_name InteractionTarget
extends RefCounted
var id: StringName
var ground: Vector2
var radius: float
var available: bool = true
var primary: String = ""
var secondary: String = ""
var visit_id: StringName
func _init(identity: StringName = &"", anchor: Vector2 = Vector2.ZERO, reach: float = 1.6) -> void:
 id = identity
 ground = anchor
 radius = reach
