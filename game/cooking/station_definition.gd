class_name StationDefinition
extends RefCounted
var id: StringName
var recipe_id: StringName
func _init(identity: StringName = &"", recipe: StringName = &"") -> void:
 id = identity
 recipe_id = recipe
