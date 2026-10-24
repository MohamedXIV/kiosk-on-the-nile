class_name LocationRegistry
extends RefCounted
var _kinds: Dictionary={}
func configure(locations: Dictionary, routes: Dictionary) -> ActionResult:
 _kinds.clear()
 for id in locations:_kinds[id]="physical"
 _kinds["transit"]="transit"
 for route in routes.values():
  if route.get("kind") in ["shop","office"]:_kinds[str(route.destination)]=str(route.kind)
 return ActionResult.success()
func kind(id: StringName) -> StringName:
 return StringName(_kinds.get(str(id),""))
func is_physical(id: StringName) -> bool:
 return kind(id)==&"physical"
func ids() -> Array:
 return _kinds.keys()
