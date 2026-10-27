class_name ItemChangeSet
extends RefCounted
## A complete candidate at a known store revision; no side effects until commit.
var revision: int
var state: Dictionary
func _init(source_revision: int, candidate: Dictionary) -> void:
 revision = source_revision
 state = candidate.duplicate(true)
