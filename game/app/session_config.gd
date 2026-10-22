class_name SessionConfig
extends RefCounted
const REQUIRED_SECTIONS := ["time","balance","needs","social","spatial","locations","recipes","visitors","encounters","ui","atmosphere","session"]
var data: Dictionary
var fingerprint: String
var source_root: String
func _init(bundle: Dictionary = {}, revision: String = "", source: String = "res://content") -> void:
 data = bundle.duplicate(true)
 fingerprint = revision
 source_root = source
func section(id: String) -> Dictionary:
 return data.get(id,{}).duplicate(true)
