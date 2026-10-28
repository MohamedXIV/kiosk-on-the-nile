class_name CharacterMotionValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var spatial: Dictionary=bundle.get("spatial",{})
 if spatial.get("character",{}).has("idle"):
  var idle: Variant=spatial.character.idle
  if not idle is Dictionary or not idle.get("enabled") is bool:return _fail("character.idle")
  for key in ["breath_period_seconds","blink_interval_seconds","blink_duration_seconds","look_interval_seconds","look_hold_seconds"]:
   if not _interval(idle.get(key),0.03,120):return _fail("character.idle."+key)
  if float(idle.blink_duration_seconds[1])>=float(idle.blink_interval_seconds[0]):return _fail("character.idle.blink_timing")
  if not ContentValidation.bounded(idle.get("breath_pixels"),0,3) or not ContentValidation.bounded(idle.get("look_pixels"),0,4) or not ContentValidation.bounded(idle.get("look_smoothing"),0.1,30):return _fail("character.idle.amplitude")
 if spatial.has("navigation"):
  var nav: Variant=spatial.navigation
  if not nav is Dictionary or not nav.get("enabled") is bool:return _fail("navigation")
  if not ContentValidation.bounded(nav.get("arrival_radius"),0.08,0.14) or (bundle.has("visitors") and float(nav.arrival_radius)>=float(bundle.visitors.get("arrival_radius",0.15))):return _fail("navigation.arrival_radius")
  if not ContentValidation.bounded(nav.get("progress_distance"),0.005,0.25) or not ContentValidation.bounded(nav.get("stall_seconds"),0.25,30) or not ContentValidation.bounded(nav.get("replan_cooldown_seconds"),0.1,30):return _fail("navigation.timing")
  for key in ["max_replans","max_fallbacks"]:
   if not ContentValidation.integer(nav.get(key)) or nav[key]<0 or nav[key]>5:return _fail("navigation."+key)
 var visitors: Dictionary=bundle.get("visitors",{})
 if visitors.has("awareness"):
  var data: Variant=visitors.awareness
  if not data is Dictionary or not data.get("enabled") is bool:return _fail("visitors.awareness")
  if not ContentValidation.bounded(data.get("sample_seconds"),0.2,5) or not ContentValidation.bounded(data.get("sight_radius"),1,20) or not ContentValidation.bounded(data.get("memory_seconds"),5,300):return _fail("visitors.awareness.policy")
 if visitors.has("meetings"):
  var data: Variant=visitors.meetings
  if not data is Dictionary or not data.get("enabled") is bool or not data.get("actors") is Array or data.actors.size()>4:return _fail("visitors.meetings")
  for actor in data.actors:
   if not actor is String or not visitors.characters.has(actor) or not actor in bundle.get("social_life",{}).get("companionship",{}).get("actors",[]):return _fail("visitors.meetings.actor")
  if data.has("delay_overrides"):
   if not data.delay_overrides is Dictionary or data.delay_overrides.size()>4:return _fail("visitors.meetings.delay_overrides")
   for actor in data.delay_overrides:
    if not actor in data.actors or not _interval(data.delay_overrides[actor],5,300):return _fail("visitors.meetings.delay_override")
  if not _interval(data.get("delay_seconds"),5,300) or not ContentValidation.bounded(data.get("chance"),0,1):return _fail("visitors.meetings.schedule")
  if not ContentValidation.bounded(data.get("retarget_seconds"),0.5,10) or not ContentValidation.bounded(data.get("retarget_distance"),0.25,3) or not ContentValidation.bounded(data.get("max_seconds"),5,120) or not ContentValidation.bounded(data.get("lost_wait_seconds"),1,30):return _fail("visitors.meetings.timing")
  if not ContentValidation.bounded(data.get("stop_distance"),0.7,2.5) or float(data.stop_distance)+0.15>=float(bundle.get("social_life",{}).get("companionship",{}).get("radius",1.8)):return _fail("visitors.meetings.distance")
  if data.enabled and not visitors.get("awareness",{}).get("enabled",false):return _fail("visitors.meetings.awareness_required")
 if visitors.has("leisure"):
  var data: Variant=visitors.leisure
  if not data is Dictionary or not data.get("enabled") is bool or not _interval(data.get("interval_minutes"),1,1440):return _fail("visitors.leisure")
  if not ContentValidation.bounded(data.get("chance"),0,1) or not ContentValidation.bounded(data.get("max_distance"),0.5,15) or not ContentValidation.integer(data.get("max_moves")) or data.max_moves<0 or data.max_moves>5:return _fail("visitors.leisure.policy")
  var markers: Dictionary=bundle.get("locations",{}).get("kiosk",{}).get("markers",{})
  if not data.get("markers") is Array or data.markers.is_empty() or data.markers.size()>32:return _fail("visitors.leisure.markers")
  for key in data.markers:
   if not key is String or not markers.has(key):return _fail("visitors.leisure.marker")
 var residential: Dictionary=bundle.get("residential_visits",{})
 for key in ["standing_alternatives","exit_alternatives"]:
  if not residential.has(key):continue
  if not residential[key] is Array or residential[key].size()>16:return _fail("residential."+key)
  for point in residential[key]:
   if not ContentValidation.vector(point,2):return _fail("residential."+key)
 return ActionResult.success()
static func _interval(value: Variant, minimum: float, maximum: float) -> bool:
 return value is Array and value.size()==2 and ContentValidation.bounded(value[0],minimum,maximum) and ContentValidation.bounded(value[1],float(value[0]),maximum)
static func _fail(key: String) -> ActionResult:
 return ContentValidation.fail(key)
