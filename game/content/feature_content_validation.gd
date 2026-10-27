class_name FeatureContentValidation
extends RefCounted
## Cross-feature authoring references are checked before ContentStore activates a bundle.
static func validate(bundle: Dictionary) -> ActionResult:
 if bundle.has("wellbeing"):
  var policy: Variant = bundle.wellbeing
  if not policy is Dictionary or not policy.get("sleep") is Dictionary or not policy.get("oversleep_rules") is Array or not policy.get("quality_rules") is Array: return ContentValidation.fail("wellbeing")
  for field in ["minimum_hours","maximum_hours","step_hours","default_hours"]:
   if not ContentValidation.integer(policy.sleep.get(field)): return ContentValidation.fail("wellbeing.sleep."+field)
  var settings: Dictionary = policy.sleep
  if settings.minimum_hours<1 or settings.maximum_hours>12 or settings.minimum_hours>settings.maximum_hours or settings.step_hours<1 or settings.default_hours<settings.minimum_hours or settings.default_hours>settings.maximum_hours or (int(settings.default_hours)-int(settings.minimum_hours))%int(settings.step_hours)!=0: return ContentValidation.fail("wellbeing.sleep")
  var previous_penalty := 3
  var previous_threshold := -1.0
  for rule in policy.quality_rules:
   if not rule is Dictionary or not ContentValidation.bounded(rule.get("mood_below"),0,100) or not ContentValidation.integer(rule.get("penalty")) or not ContentValidation.bounded(rule.penalty,0,2) or rule.mood_below<=previous_threshold or rule.penalty>previous_penalty: return ContentValidation.fail("wellbeing.quality_rules")
   previous_penalty = int(rule.penalty)
   previous_threshold = float(rule.mood_below)
  for rule in policy.oversleep_rules:
   if not rule is Dictionary or not ContentValidation.bounded(rule.get("mood_below"),0,100) or not ContentValidation.bounded(rule.get("rest_below"),0,100) or not ContentValidation.integer(rule.get("extra_hours")) or not ContentValidation.bounded(rule.extra_hours,0,2): return ContentValidation.fail("wellbeing.oversleep_rules")
 if bundle.has("session"):
  var initial: Variant = bundle.session
  if not initial is Dictionary or not initial.get("kiosk_open") is bool or not initial.get("home") is Dictionary or not initial.home.get("has_fan") is bool or not initial.home.get("fan_on") is bool or (initial.home.fan_on and not initial.home.has_fan): return ContentValidation.fail("session.initial")
 if bundle.has("visitors"):
  var data: Variant = bundle.visitors
  if not data is Dictionary or not data.get("characters") is Dictionary or data.characters.is_empty(): return ContentValidation.fail("visitors.characters")
  if not ContentValidation.integer(data.get("seed")) or not ContentValidation.integer(data.get("capacity")) or data.capacity<1 or data.capacity>4:return ContentValidation.fail("visitors.capacity")
  for field in ["arrival_radius","interaction_radius","waiting_reminder_seconds","max_wait_seconds","personal_space"]:
   if not ContentValidation.number(data.get(field)) or data[field]<=0:return ContentValidation.fail("visitors."+field)
  for field in ["initial_delay","arrival_delay","purchase_delay","purchase_retry_delay","stay_multiplier","ambient_remark_delay"]:
   if not ContentValidation.vector(data.get(field),2) or data[field][0]<=0 or data[field][0]>data[field][1]:return ContentValidation.fail("visitors."+field)
  for id in ["amgad","mahmoud","samir"]:
   if not data.characters.has(id): return ContentValidation.fail("visitors.required_character")
  var markers: Dictionary = bundle.get("locations",{}).get("kiosk",{}).get("markers",{})
  for field in ["spawn_markers","exit_markers"]:
   if not data.get(field) is Array or data[field].is_empty(): return ContentValidation.fail("visitors."+field)
   for key in data[field]:
    if not key is String or not ContentValidation.vector(markers.get(key),2): return ContentValidation.fail("visitors.spawn_marker")
  for id in data.characters:
   var character: Variant = data.characters[id]
   if not character is Dictionary or not character.get("name") is String or not character.get("color") is String or not Color.html_is_valid(character.color) or not character.get("marker") is String or not markers.has(character.marker) or (character.get("food_id")!="" and not bundle.get("foods",{}).has(str(character.get("food_id","")))) or not ContentValidation.number(character.get("stay_seconds")) or character.stay_seconds<=0 or not character.get("ambient") is bool: return ContentValidation.fail("visitors.characters."+id)
   if not markers.has(str(character.get("leisure_marker",""))) or not ContentValidation.bounded(character.get("arrival_weight"),0.01,100) or not ContentValidation.bounded(character.get("purchase_chance"),0,1):return ContentValidation.fail("visitors.leisure_policy")
   if character.has("food_preferences"):
    if not character.food_preferences is Dictionary:return ContentValidation.fail("visitors.food_preferences")
    for food_id in character.food_preferences:
     if not bundle.get("foods",{}).has(food_id) or not ContentValidation.integer(character.food_preferences[food_id]) or character.food_preferences[food_id]<1 or character.food_preferences[food_id]>20:return ContentValidation.fail("visitors.food_preferences")
   for encounter in character.get("manual_encounters",[]):
    if not bundle.get("encounters",{}).has(encounter):return ContentValidation.fail("visitors.manual_encounter")
   if not character.get("visit_policy") is Dictionary: return ContentValidation.fail("visitors.visit_policy."+id)
   var policy: Dictionary = character.visit_policy
   if not ContentValidation.integer(policy.get("daily_limit")) or not ContentValidation.bounded(policy.daily_limit,1,20) or not ContentValidation.bounded(policy.get("return_after_minutes"),0,10080) or not ContentValidation.vector(policy.get("time_window"),2) or policy.time_window[0]<0 or policy.time_window[0]>=policy.time_window[1] or policy.time_window[1]>1440: return ContentValidation.fail("visitors.visit_policy."+id)
   var anchor: Array = markers[character.marker]
   var kiosk: Dictionary = bundle.locations.kiosk
   if FootprintGeometry.blocked(Vector2(anchor[0],anchor[1]),kiosk.solids,float(kiosk.navigation_clearance)): return ContentValidation.fail("visitors.blocked_marker."+id)
 if bundle.has("ui"):
  var ui: Variant = bundle.ui
  if not ui is Dictionary: return ContentValidation.fail("ui")
  for key in ["title","subtitle","new_game","continue","save","saved","save_failed","load_failed","notebook","close","help","money","day_time","hunger","rest","mood","stock","held","empty_hands","open","closed","talk","serve","consume","interaction","secondary","success","sleep_title","sleep_hours_suffix","sleep_confirm","sleep_cancel","sleep_preview","sleep_oversleep","sleep_on_time","sleep_recovery","sleeping","sleep_completed","craft_mood_penalty","work_mood_hint"]:
   if not ui.get(key) is String: return ContentValidation.fail("ui."+key)
  for key in ["menu","stock_short"]:
   if not ui.get(key) is String: return ContentValidation.fail("ui."+key)
  if not ui.get("hud") is Dictionary: return ContentValidation.fail("ui.hud")
  for field in ["margin","font_size","meter_width","dialogue_font_size"]:
   if not ContentValidation.bounded(ui.hud.get(field),4,100): return ContentValidation.fail("ui.hud."+field)
  for field in ["dialogue_width_ratio","dialogue_max_height_ratio","prompt_width_ratio"]:
   if not ContentValidation.bounded(ui.hud.get(field),0.2,0.95): return ContentValidation.fail("ui.hud."+field)
  if not ui.hud.get("meter_colors") is Dictionary: return ContentValidation.fail("ui.hud.meter_colors")
  for key in ["hunger","rest","mood"]:
   if not ui.hud.meter_colors.get(key) is String or not Color.html_is_valid(ui.hud.meter_colors[key]): return ContentValidation.fail("ui.hud.meter_colors."+key)
  if not ui.get("sleep_dim_color") is String or not Color.html_is_valid(ui.sleep_dim_color): return ContentValidation.fail("ui.sleep_dim_color")
  for key in ["theme","input","errors","transition","toasts"]:
   if not ui.get(key) is Dictionary: return ContentValidation.fail("ui."+key)
  for key in ["background","border","text","accent"]:
   if not ui.theme.get(key) is String or not Color.html_is_valid(ui.theme[key]): return ContentValidation.fail("ui.theme."+key)
  if not ContentValidation.bounded(ui.theme.get("font_size"),12,48) or not ContentValidation.bounded(ui.toasts.get("duration"),0.1,30): return ContentValidation.fail("ui.theme")
  for key in ["fade_out","fade_in"]:
   if not ContentValidation.bounded(ui.transition.get(key),0.01,10): return ContentValidation.fail("ui.transition")
  for action in ["move_left","move_right","move_up","move_down","interact_primary","interact_secondary","notebook","cancel"]:
   if not ui.input.get(action) is Array or ui.input[action].is_empty(): return ContentValidation.fail("ui.input."+action)
   for key in ui.input[action]:
    if not key is String or OS.find_keycode_from_string(key)==KEY_NONE: return ContentValidation.fail("ui.input."+action)
  for value in ui.errors.values():
   if not value is String: return ContentValidation.fail("ui.errors")
 if bundle.has("atmosphere"):
  var data: Variant = bundle.atmosphere
  if not data is Dictionary: return ContentValidation.fail("atmosphere")
  for field in ["audio","night","steam","light"]:
   if not data.get(field) is Dictionary: return ContentValidation.fail("atmosphere."+field)
  if not ContentValidation.bounded(data.audio.get("fade_speed"),0.01,100) or not data.audio.get("layers") is Dictionary or not data.audio.get("cues") is Dictionary: return ContentValidation.fail("atmosphere.audio")
  for layer in data.audio.layers.values():
   if not layer is Dictionary or not layer.get("path") is String or not ResourceLoader.exists(layer.path,"AudioStream"): return ContentValidation.fail("atmosphere.audio.path")
   for location in ["kiosk_gain","rooftop_gain"]:
    if not ContentValidation.bounded(layer.get(location),0,1): return ContentValidation.fail("atmosphere.audio.gain")
  for path in data.audio.cues.values():
   if not path is String or not ResourceLoader.exists(path,"AudioStream"): return ContentValidation.fail("atmosphere.audio.cue")
  if not ContentValidation.bounded(data.night.get("start"),0,1440) or not ContentValidation.bounded(data.night.get("end"),0,1440) or data.night.start>=data.night.end: return ContentValidation.fail("atmosphere.night")
  if not ContentValidation.bounded(data.night.get("morning_end"),0,data.night.start) or not data.night.get("color") is String or not Color.html_is_valid(data.night.color): return ContentValidation.fail("atmosphere.night.color")
  for field in ["afternoon_factor","night_factor","opacity"]:
   if not ContentValidation.bounded(data.night.get(field),0,1): return ContentValidation.fail("atmosphere.night."+field)
  for field in ["interval","rise_speed","lifetime","radius"]:
   if not ContentValidation.bounded(data.steam.get(field),0.01,200): return ContentValidation.fail("atmosphere.steam."+field)
  if not data.light.get("color") is String or not Color.html_is_valid(data.light.color) or not ContentValidation.bounded(data.light.get("radius"),1,1000) or not ContentValidation.bounded(data.light.get("energy"),0,5): return ContentValidation.fail("atmosphere.light")
 if bundle.has("encounters"):
  if not bundle.encounters is Dictionary or not bundle.has("social") or not bundle.has("visitors"): return ContentValidation.fail("encounters")
  var actors: Array = bundle.visitors.characters.keys()+bundle.get("residential_visits",{}).get("profiles",{}).keys()+bundle.get("suppliers",{}).get("profiles",{}).keys()
  actors.append("player")
  var relationship_validation := RelationshipStore.new(bundle.social,actors).restore({"values":bundle.social.get("initial_relationships",{})})
  if not relationship_validation.ok: return ContentValidation.fail("social.initial_relationships")
  var evaluator := ConditionEvaluator.new(KnowledgeBook.new(bundle.social),RelationshipStore.new(bundle.social,actors),GameClock.new(bundle.time),VisitorService.new(),HomeService.new(ItemStore.new()),ActorPose.new(),bundle.social.facts,actors,bundle.get("locations",{}).keys())
  evaluator.social_actions=bundle.get("social_life",{}).get("actions",{}).keys()
  evaluator.social_topics=bundle.get("social_life",{}).get("topics",{}).keys()
  evaluator.recipe_ids=bundle.get("recipe_workflows",{}).keys()+bundle.get("learning",{}).get("families",{}).values()
  for rule in bundle.get("narration",{}).get("thoughts",[]):
   if not evaluator.validate(rule.requires):return ContentValidation.fail("narration.thought.requires")
  for id in bundle.encounters:
   var definition: Variant = bundle.encounters[id]
   if not definition is Dictionary or not definition.get("story") is String or not bundle.get("story_"+str(definition.story)) is Dictionary: return ContentValidation.fail("encounters."+id)
   var story: Dictionary = bundle["story_"+definition.story]
   if not ContentValidation.integer(story.get("inkVersion")) or not story.get("root") is Array: return ContentValidation.fail("story_"+definition.story)
   if not definition.get("requires_pending_order",false) is bool:return ContentValidation.fail("encounters.pending_order")
   for field in ["requires","offer_requires"]:
    if not evaluator.validate(definition.get(field,{})): return ContentValidation.fail("encounters."+id+"."+field)
   if not definition.get("choice_conditions",{}) is Dictionary: return ContentValidation.fail("encounters.choice_conditions")
   if not definition.get("context_conditions",{}) is Dictionary: return ContentValidation.fail("encounters.context_conditions")
   for rule in definition.get("choice_conditions",{}).values()+definition.get("context_conditions",{}).values():
    if not evaluator.validate(rule): return ContentValidation.fail("encounters.choice_conditions")
   if definition.has("topics"):
    if not definition.topics is Array or definition.topics.is_empty(): return ContentValidation.fail("encounters.topics")
    var topics: Dictionary = {}
    for topic in definition.topics:
     if not topic is Dictionary or not topic.get("id") is String or not topic.id.is_valid_identifier() or topics.has(topic.id) or not topic.get("scope") in ["once","day","visit","evidence"] or not ContentValidation.integer(topic.get("variants")) or not ContentValidation.bounded(topic.variants,1,16) or not topic.get("modes") is Array or topic.modes.is_empty() or not evaluator.validate(topic.get("requires",{})): return ContentValidation.fail("encounters.topics."+id)
     if topic.scope=="evidence" and topic.get("source_type")!="visit" and not topic.get("recipe_id") in evaluator.recipe_ids:return ContentValidation.fail("encounters.evidence_recipe")
     topics[topic.id] = true
     for mode in topic.modes:
      if not ContentValidation.integer(mode) or not ContentValidation.bounded(mode,0,4): return ContentValidation.fail("encounters.topics.mode")
     if topic.has("minimum_visits") and (not ContentValidation.integer(topic.minimum_visits) or topic.minimum_visits<0): return ContentValidation.fail("encounters.topics.minimum_visits")
     if topic.has("requires_previous_service") and not topic.requires_previous_service is bool: return ContentValidation.fail("encounters.topics.service_memory")
     if topic.has("characters"):
      if not topic.characters is Array or topic.characters.is_empty(): return ContentValidation.fail("encounters.topics.characters")
      for actor in topic.characters:
       if not actor in bundle.visitors.characters: return ContentValidation.fail("encounters.topics.characters")
   if definition.has("peer") and not definition.peer is bool:return ContentValidation.fail("encounters.peer")
   if definition.get("optional",false):
    if not ContentValidation.bounded(definition.get("choice_expiry"),0.1,120) or (not definition.get("peer",false) and (not ContentValidation.integer(definition.get("listen_choice")) or definition.listen_choice<0)): return ContentValidation.fail("encounters.optional")
  for location in bundle.get("locations",{}).values():
   for interaction in location.interactions:
    for action in [interaction.get("action",""),interaction.get("secondary_action","")]:
     if not action in ["","cook","sugar","toggle_kiosk","travel","buy_stock","buy_fan","snack","toggle_fan","river","sleep"]: return ContentValidation.fail("locations.interaction_action")
    if interaction.get("action")=="travel" or interaction.get("secondary_action")=="travel":
     if not bundle.locations.has(interaction.get("destination")): return ContentValidation.fail("locations.interaction_destination")
    for field in ["requires","secondary_requires"]:
     if not evaluator.validate(interaction.get(field,{})): return ContentValidation.fail("locations.interaction_condition")
    if interaction.get("action")=="cook" and not bundle.get("recipes",{}).get("stations",{}).has(interaction.get("station_id")): return ContentValidation.fail("locations.station_id")
 return ActionResult.success()
