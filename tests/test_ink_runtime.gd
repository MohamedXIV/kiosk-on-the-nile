extends RefCounted
func run(check, tree) -> void:
 check.case("latest_engine")
 check.equal(Engine.get_version_info().major, 4)
 check.equal(Engine.get_version_info().minor, 7)
 check.equal(Engine.get_version_info().patch, 2)
 check.case("pending_choice_resume")
 var path := "res://game/narrative/ink_runtime.gd"
 check.is_true(FileAccess.file_exists(path))
 if not FileAccess.file_exists(path): return
 var Runtime = load(path)
 var Definition = load("res://game/narrative/story_definition.gd")
 var definition = Definition.new()
 definition.id = &"qualification"
 definition.compiled_path = "res://tests/fixtures/qualification.ink.json"
 definition.sha256 = FileAccess.get_file_as_string(definition.compiled_path).sha256_text()
 var runtime = Runtime.new()
 tree.root.add_child(runtime)
 var opened = await runtime.open(definition, {"day":1})
 check.is_true(opened.ok)
 if not opened.ok:
  runtime.queue_free()
  return
 var frame = runtime.advance()
 check.equal(frame.choices.size(), 2)
 var saved = runtime.snapshot()
 check.case("invalid_choice_does_not_advance")
 check.equal(runtime.choose(-1).code, 8)
 check.equal(runtime.snapshot(), saved)
 var restored = Runtime.new()
 tree.root.add_child(restored)
 await restored.open(definition, {})
 check.is_true(restored.restore(saved).ok)
 check.equal(restored.frame().choices, frame.choices)
 check.is_true(restored.choose(0).ok)
 check.equal(restored.advance().text, "تسلم يا معلم.")
 check.case("unknown_metadata_rejected")
 var invalid = Definition.new()
 invalid.id = &"invalid"
 invalid.compiled_path = "res://tests/fixtures/unknown_tag.ink.json"
 invalid.sha256 = FileAccess.get_file_as_string(invalid.compiled_path).sha256_text()
 var broken = Runtime.new()
 tree.root.add_child(broken)
 await broken.open(invalid, {})
 var bad_frame = broken.advance()
 check.is_true(not bad_frame.result.ok)
 check.equal(bad_frame.effects.size(), 0)
 runtime.close()
 restored.close()
 broken.close()
 runtime.queue_free()
 restored.queue_free()
 broken.queue_free()
 await tree.process_frame
