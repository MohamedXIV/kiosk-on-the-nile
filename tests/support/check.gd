extends RefCounted
var assertions := 0
var failures := 0
var cases := 0
var label := ""
func case(name: String) -> void:
 cases += 1
 label = name
func equal(actual: Variant, expected: Variant) -> void:
 assertions += 1
 if actual != expected:
  failures += 1
  print("FAIL ", label, ": expected ", expected, ", got ", actual)
func near(actual: float, expected: float, epsilon: float = 0.00001) -> void:
 assertions += 1
 if absf(actual - expected) > epsilon:
  failures += 1
  print("FAIL ", label, ": expected ", expected, ", got ", actual)
func is_true(value: bool) -> void:
 equal(value, true)
