class_name LocationDefinition
extends RefCounted
var id: StringName
var data: Dictionary
func _init(identity: StringName = &"", definition: Dictionary = {}) -> void:
 id = identity
 data = definition.duplicate(true)
func marker(identity: StringName) -> Vector2:
 var value: Array = data.get("markers",{}).get(str(identity),[0,0])
 return Vector2(value[0],value[1])
