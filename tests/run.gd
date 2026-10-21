extends SceneTree
const Check = preload("res://tests/support/check.gd")
func _initialize() -> void:
 call_deferred("execute")
func execute() -> void:
 var args := OS.get_cmdline_user_args()
 var suite := "all"
 if "--suite" in args:
  suite = args[args.find("--suite") + 1]
 var check = Check.new()
 var files: Array[String] = []
 for file in DirAccess.get_files_at("res://tests"):
  if file.begins_with("test_") and file.ends_with(".gd") and (suite == "all" or file == "test_" + suite + ".gd"):
   files.append(file)
 for file in files:
  var script = load("res://tests/" + file)
  if script == null or not script.can_instantiate():
   check.case(file)
   check.is_true(false)
   continue
  var test = script.new()
  await test.run(check, self)
 print("TESTS: ", check.cases, " cases, ", check.assertions, " assertions, ", check.failures, " failures")
 quit(0 if check.failures == 0 and check.cases > 0 else 1)
