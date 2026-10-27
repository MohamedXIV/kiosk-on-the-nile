class_name HudContentValidation
extends RefCounted
## Optional presentation metadata; the domain inventory and clock are unchanged.
static func validate(bundle: Dictionary) -> ActionResult:
 var ui: Dictionary=bundle.get("ui",{})
 var hud: Dictionary=ui.get("hud",{})
 if not hud.has("icons"):return ActionResult.success()
 var icons: Variant=hud.icons
 if not icons is Dictionary or not ContentValidation.bounded(icons.get("size"),12,40):return ContentValidation.fail("ui.hud.icons.size")
 if not icons.get("needs") is Dictionary:return ContentValidation.fail("ui.hud.icons.needs")
 for key in ["hunger","rest","mood"]:
  if not _texture(icons.needs.get(key)):return ContentValidation.fail("ui.hud.icons.needs."+key)
 var periods: Variant=icons.get("day_periods")
 if not periods is Array or periods.is_empty() or periods.size()>12:return ContentValidation.fail("ui.hud.icons.day_periods")
 var previous: int=-1
 for period in periods:
  if not period is Dictionary:return ContentValidation.fail("ui.hud.icons.period")
  if not ContentValidation.integer(period.get("start_minute")) or period.start_minute<0 or period.start_minute>=1440 or period.start_minute<=previous:return ContentValidation.fail("ui.hud.icons.period.start_minute")
  if previous<0 and period.start_minute!=0:return ContentValidation.fail("ui.hud.icons.period.midnight")
  if not period.get("label") is String or not ui.get(period.label) is String or not _texture(period.get("path")):return ContentValidation.fail("ui.hud.icons.period.presentation")
  previous=int(period.start_minute)
 return ActionResult.success()
static func _texture(value: Variant) -> bool:
 return value is String and value.begins_with("res://") and ResourceLoader.exists(value,"Texture2D")
