extends RefCounted
func run(check, _tree) -> void:
 check.case("external_json_content_exists")
 var path := "res://game/content/content_store.gd"
 check.is_true(FileAccess.file_exists(path))
 if not FileAccess.file_exists(path): return
 var store = load(path).new()
 check.is_true(store.load_directory("res://content").ok)
 check.equal(store.section("time").minutes_per_second, 2.5)
 var before = store.fingerprint
 check.case("invalid_override_is_atomic")
 check.is_true(not store.load_directory("/tmp/does-not-exist-kiosk-content").ok)
 check.equal(store.fingerprint, before)
 check.case("external_data_reload_without_engine_rebuild")
 var temporary := "/tmp/kiosk-content-" + str(Time.get_ticks_usec())
 DirAccess.make_dir_recursive_absolute(temporary)
 var file := FileAccess.open(temporary.path_join("manifest.json"), FileAccess.WRITE)
 file.store_string('{"schema_version":1,"sections":{"time":"time.json"}}')
 file.close()
 file = FileAccess.open(temporary.path_join("time.json"), FileAccess.WRITE)
 file.store_string('{"minutes_per_second":3}')
 file.close()
 check.is_true(store.load_directory(temporary).ok)
 check.equal(store.section("time").minutes_per_second, 3)
 var valid_fingerprint: String = store.fingerprint
 file = FileAccess.open(temporary.path_join("time.json"), FileAccess.WRITE)
 file.store_string('{"minutes_per_second":-1}')
 file.close()
 check.is_true(not store.load_directory(temporary).ok)
 check.equal(store.fingerprint, valid_fingerprint)
 var copy: Dictionary = store.section("time")
 copy.minutes_per_second = 99
 check.equal(store.section("time").minutes_per_second, 3)
 DirAccess.remove_absolute(temporary.path_join("manifest.json"))
 DirAccess.remove_absolute(temporary.path_join("time.json"))
 DirAccess.remove_absolute(temporary)
 store.free()
