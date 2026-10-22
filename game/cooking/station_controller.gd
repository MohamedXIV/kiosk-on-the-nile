class_name StationController
extends RefCounted
var cooking: CookingService
var _primary_key: String
func _init(source: CookingService, primary_key: String = "E") -> void:
 cooking = source
 _primary_key = primary_key
func status_label(station_id: StringName, compact: bool = false) -> String:
 var current := cooking.job(station_id)
 if current == null: return ""
 var recipe := current.recipe
 var stage := str(current.stage)
 if recipe.rules_id == &"tea" and stage == "READY" and current.brew_elapsed > float(recipe.data.timing.warning_after): stage = "READY_LATE"
 if recipe.rules_id == &"kebda" and stage == "SIDE_A":
  if current.side_a_elapsed < float(recipe.data.timing.excellent_a_min): stage = "SIDE_A_EARLY"
  elif current.side_a_elapsed <= float(recipe.data.timing.excellent_a_max): stage = "SIDE_A_READY"
  else: stage = "SIDE_A_LATE"
 if recipe.rules_id == &"kebda" and stage == "SEASONED" and current.side_b_elapsed > float(recipe.data.timing.warning_after): stage = "SEASONED_LATE"
 var labels: Dictionary = recipe.data.compact if compact else recipe.data.status
 var label: String = labels.get(stage,"")
 var sugar := ""
 for option in recipe.data.get("sugars",[]):
  if option.id == str(current.sugar_id): sugar = option.label
 var progress := mini(100,floori(current.heat_elapsed/float(recipe.data.timing.get("boil_seconds",1))*100))
 return label.format({"sugar":sugar,"progress":progress,"key":_primary_key})
