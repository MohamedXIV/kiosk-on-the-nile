class_name NarrativeDirector
extends Node
var history := ConversationHistory.new()
signal changed
signal failed(result: ActionResult)
var sessions: Dictionary = {}
var _stories: Dictionary = {}
var _definitions: Dictionary
var _session: GameSession
var _next: int = 1
var _focus: StringName
var _opening: Dictionary = {}
func configure(session: GameSession, definitions: Dictionary, stories: Dictionary) -> ActionResult:
 _session = session
 _definitions = definitions.duplicate(true)
 _stories = stories.duplicate()
 for id in _definitions:
  if not _stories.has(_definitions[id].get("story")) or not session.conditions.validate(_definitions[id].get("requires",{})) or not session.conditions.validate(_definitions[id].get("offer_requires",{})): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_encounter")
  for rule in _definitions[id].get("choice_conditions",{}).values()+_definitions[id].get("context_conditions",{}).values():
   if not session.conditions.validate(rule): return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_choice_condition")
 return ActionResult.success()
func context(participants: PackedStringArray, extra: Dictionary = {}) -> Dictionary:
 var character_id := "hassan"
 if not participants.is_empty() and _session.visitors.visits.has(participants[0]): character_id = str(_session.visitors.visits[participants[0]].character_id)
 var intended_food := ""
 if not participants.is_empty() and _session.visitors.visits.has(participants[0]): intended_food=str(_session.visitors.visits[participants[0]].food_id)
 var quality: String = _session.visitors.memory.last_served_quality
 var recipe: Dictionary = _session.config.section("recipes").recipes.tea
 for i in range(recipe.quality_keys.size()):
  if recipe.quality_keys[i] == quality: quality = recipe.quality_names[str(i)]
 var data := {"day":_session.clock.day,"amgad_visits":_session.visitors.memory.amgad_visits,"last_served_quality":quality if not quality.is_empty() else "مظبوط","known_cheap_fan":_session.knowledge.has(&"KNOWN_CHEAP_FAN"),"familiarity":_session.relationships.value(&"player",StringName(character_id),&"familiarity"),"character_id":character_id,"fan_price_label":String.num(float(_session.config.section("balance").fan_price)/100.0,2),"familiar":_session.relationships.value(&"player",StringName(character_id),&"familiarity")>=float(_session.config.section("social").conversation_familiarity_threshold),"mode":0,"quality_score":0,"order_label":_session.config.section("recipes").stock_labels.get(intended_food,"")}
 var visit: VisitState = _session.visitors.visits.get(participants[0]) if not participants.is_empty() else null
 var previous := _session.visitors.history.previous_service(character_id,visit.id) if visit else {}
 data.merge({"topic_id":"","line_variant":0,"hour":int(_session.clock.minutes)/60,"bought_fan":_session.home.has_fan,"visit_count":_session.visitors.visit_count(StringName(character_id)),"previous_quality":int(previous.get("quality",-1)),"previous_food":str(previous.get("food_id",""))},true)
 data.merge(extra,true)
 return data
func start(encounter_id: StringName, participants: PackedStringArray, extra: Dictionary = {}) -> ActionResult:
 var definition: Dictionary = _definitions.get(str(encounter_id),{})
 if definition.is_empty() or not _session.conditions.permits(definition.get("requires",{}),participants): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_unavailable")
 var key := str(encounter_id)+":"+",".join(participants)
 if _opening.has(key): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_opening")
 for existing in sessions.values():
  if not existing.finished and existing.encounter_id==encounter_id and existing.participants==participants and int(existing.context_extra.get("mode",0))==int(extra.get("mode",0)): return ActionResult.success({"session_id":str(existing.id)})
 var selected := _select_topic(encounter_id,participants,extra)
 if definition.has("topics") and selected.is_empty(): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"nothing_new_to_say")
 if encounter_id in [&"amgad",&"visitors"] and int(extra.get("mode",0))==0:
  for existing: ConversationSession in sessions.values():
   if existing.participants==participants and existing.current.choices.is_empty() and existing.encounter_id!=&"football": _finish(existing)
 _opening[key] = true
 var conversation := ConversationSession.new()
 conversation.id = StringName("conversation_%d" % _next)
 _next += 1
 conversation.encounter_id = encounter_id
 conversation.participants = participants.duplicate()
 conversation.optional = bool(definition.get("optional",false))
 conversation.topic_selection = selected
 conversation.context_extra = extra.duplicate(true)
 if not selected.is_empty(): conversation.context_extra.merge({"topic_id":selected.topic_id,"line_variant":selected.variant},true)
 conversation.runtime = InkRuntime.new()
 add_child(conversation.runtime)
 var result := await conversation.runtime.open(_stories[definition.story],_context_for(conversation))
 _opening.erase(key)
 if not result.ok or not _session.conditions.permits(definition.get("requires",{}),participants):
  conversation.runtime.queue_free()
  return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_unavailable")
 sessions[str(conversation.id)] = conversation
 _advance(conversation)
 return ActionResult.success({"session_id":str(conversation.id)})
func tick(delta: float) -> void:
 for conversation: ConversationSession in sessions.values():
  if conversation.finished: continue
  var definition: Dictionary = _definitions[str(conversation.encounter_id)]
  if not _session.conditions.permits(definition.get("requires",{}),conversation.participants):
   cancel(conversation.id)
   continue
  conversation.elapsed += delta
  if not conversation.current.choices.is_empty():
   conversation.choice_elapsed += delta
   if conversation.optional and conversation.choice_elapsed>=float(definition.get("choice_expiry",8)):
    var listen := str(definition.get("listen_choice",2))
    choose(conversation.id,StringName("%s:%d:%s" % [conversation.id,conversation.beat,listen]),true)
   elif _focus.is_empty() and _can_offer(conversation): _focus = conversation.id; changed.emit()
  elif conversation.elapsed>=maxf(conversation.current.duration,0.05):
   if conversation.current.ended: _finish(conversation)
   else: _advance(conversation)
func _can_offer(conversation: ConversationSession) -> bool:
 var definition: Dictionary = _definitions[str(conversation.encounter_id)]
 return _session.conditions.permits(definition.get("offer_requires",{}),conversation.participants)
func _advance(conversation: ConversationSession) -> void:
 conversation.runtime.set_context(_context_for(conversation))
 conversation.current = conversation.runtime.advance()
 conversation.beat += 1
 conversation.elapsed = 0
 conversation.choice_elapsed = 0
 if not conversation.current.result.ok:
  _report_failure(conversation,conversation.current.result)
  _finish(conversation)
  return
 var speaker := str(conversation.current.speaker_id)
 if not speaker.is_empty():
  var valid_speaker := false
  for id in conversation.participants:
   if _session.visitors.visits.has(id) and str(_session.visitors.visits[id].character_id)==speaker: valid_speaker=true
  if not valid_speaker:
   _report_failure(conversation,ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_story_speaker"))
   _finish(conversation)
   return
 for effect in conversation.current.effects:
  if not _session.effects.valid(effect):
   _report_failure(conversation,ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_narrative_effect"))
   _finish(conversation)
   return
 if not conversation.current.text.is_empty(): history.commit(conversation.topic_selection)
 for i in range(conversation.current.effects.size()): _session.effects.apply(conversation.current.effects[i],StringName("%s/%d/%d" % [conversation.id,conversation.beat,i]))
 if _focus.is_empty() and not conversation.current.choices.is_empty() and _can_offer(conversation): _focus = conversation.id
 changed.emit()
func choices(conversation: ConversationSession) -> Array[Dictionary]:
 var offered: Array[Dictionary] = []
 if conversation == null or conversation.finished or not _can_offer(conversation): return offered
 var rules: Dictionary = _definitions[str(conversation.encounter_id)].get("choice_conditions",{})
 for choice in conversation.current.choices:
  if _session.conditions.permits(rules.get(str(choice.id),{}),conversation.participants): offered.append({"id":str(conversation.choice_id(choice)),"text":choice.text,"index":choice.index})
 return offered
func choose(session_id: StringName, choice_id: StringName, automatic: bool = false) -> ActionResult:
 var conversation: ConversationSession = sessions.get(str(session_id))
 if conversation == null or conversation.finished: return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"stale_choice")
 var definition: Dictionary = _definitions[str(conversation.encounter_id)]
 if not _session.conditions.permits(definition.get("requires",{}),conversation.participants): return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"stale_choice")
 var candidates: Array = choices(conversation)
 if automatic and conversation.optional: candidates = conversation.current.choices.map(func(choice):return {"id":str(conversation.choice_id(choice)),"index":choice.index})
 for choice in candidates:
  if choice.id != str(choice_id): continue
  conversation.runtime.set_context(_context_for(conversation))
  var result := conversation.runtime.choose(int(choice.index))
  if not result.ok: return result
  if _focus==session_id: _focus = &""
  _advance(conversation)
  return ActionResult.success({"cue":"chime"})
 return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"stale_choice")
func focused_session() -> ConversationSession:
 var conversation: ConversationSession = sessions.get(str(_focus))
 if conversation and not conversation.finished and _can_offer(conversation): return conversation
 _focus = &""
 return null
func cancel(session_id: StringName) -> void:
 var conversation: ConversationSession = sessions.get(str(session_id))
 if conversation: _finish(conversation)
func _finish(conversation: ConversationSession) -> void:
 conversation.finished = true
 sessions.erase(str(conversation.id))
 if conversation.runtime:
  conversation.runtime.close()
  conversation.runtime.queue_free()
  conversation.runtime = null
 if _focus==conversation.id: _focus = &""
 changed.emit()
func cancel_all() -> void:
 for conversation in sessions.values():
  if not conversation.finished: _finish(conversation)
func snapshot() -> Dictionary:
 var records: Dictionary = {}
 for id in sessions:
  if not sessions[id].finished: records[id] = sessions[id].snapshot()
 return {"history":history.snapshot(),"sessions":records,"next_id":_next,"focus":str(_focus)}
func is_ready() -> bool:
 return _opening.is_empty()
func restore(data: Dictionary) -> ActionResult:
 if not data.get("sessions") is Dictionary or not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not data.get("focus") is String: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_conversations")
 if not data.get("history") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_topic_history")
 var restored_history := ConversationHistory.new()
 var history_result := restored_history.restore(data.history,_definitions,_session.config.section("visitors").characters)
 if not history_result.ok: return history_result
 var candidates: Dictionary = {}
 for id in data.sessions:
  var record: Variant = data.sessions[id]
  if not record is Dictionary or record.get("id")!=id or not _definitions.has(record.get("encounter_id")) or not record.get("participants") is Array or not ContentValidation.integer(record.get("beat")) or record.beat<1 or not ContentValidation.number(record.get("elapsed")) or record.elapsed<0 or not ContentValidation.number(record.get("choice_elapsed")) or record.choice_elapsed<0 or not record.get("runtime") is Dictionary: return _reject_candidates(candidates)
  for participant in record.participants:
   if not participant is String or not _session.visitors.visits.has(participant): return _reject_candidates(candidates)
  var conversation := ConversationSession.new()
  conversation.id = StringName(id)
  conversation.encounter_id = StringName(record.encounter_id)
  conversation.participants = PackedStringArray(record.participants)
  if not record.get("context_extra",{}) is Dictionary: return _reject_candidates(candidates)
  conversation.context_extra = record.get("context_extra",{}).duplicate(true)
  if not record.get("topic_selection",{}) is Dictionary: return _reject_candidates(candidates)
  conversation.topic_selection = record.get("topic_selection",{}).duplicate(true)
  if not conversation.topic_selection.is_empty():
   var selection_validation := ConversationHistory.new().restore({conversation.topic_selection.get("key",""):conversation.topic_selection},_definitions,_session.config.section("visitors").characters)
   if not selection_validation.ok or conversation.context_extra.get("topic_id")!=conversation.topic_selection.get("topic_id") or conversation.context_extra.get("line_variant")!=conversation.topic_selection.get("variant"): return _reject_candidates(candidates)
  conversation.beat = int(record.beat)
  conversation.elapsed = float(record.elapsed)
  conversation.choice_elapsed = float(record.choice_elapsed)
  conversation.optional = bool(_definitions[record.encounter_id].get("optional",false))
  conversation.runtime = InkRuntime.new()
  add_child(conversation.runtime)
  candidates[id] = conversation
  var story := _saved_story(record)
  if story==null: return _reject_candidates(candidates)
  var result := await conversation.runtime.open(story,_context_for(conversation))
  if not result.ok: return _reject_candidates(candidates)
  result = conversation.runtime.restore(record.runtime)
  if not result.ok: return _reject_candidates(candidates)
  conversation.current = conversation.runtime.frame()
  if not conversation.topic_selection.is_empty() and not restored_history.contains(conversation.topic_selection):
   # An Ink control-only frame can precede the first spoken line. It has not
   # consumed the topic yet, but the saved selection must still be eligible.
   if not conversation.current.text.is_empty() or not conversation.current.effects.is_empty() or conversation.participants.is_empty(): return _reject_candidates(candidates)
   var selected_visit: VisitState = _session.visitors.visits[conversation.participants[0]]
   if StableJson.stringify(restored_history.select(conversation.encounter_id,_definitions[str(conversation.encounter_id)],selected_visit,_session,int(conversation.context_extra.get("mode",0))))!=StableJson.stringify(conversation.topic_selection): return _reject_candidates(candidates)
  for effect in conversation.current.effects:
   if not _session.effects.valid(effect): return _reject_candidates(candidates)
  # Loaded choices must still satisfy canonical eligibility. Never replay effects.
  if not _session.conditions.permits(_definitions[record.encounter_id].get("requires",{}),conversation.participants): return _reject_candidates(candidates)
 cancel_all()
 history = restored_history
 sessions = candidates
 _next = int(data.next_id)
 _focus = StringName(data.focus) if candidates.has(data.focus) else &""
 return ActionResult.success()
func _reject_candidates(candidates: Dictionary) -> ActionResult:
 for conversation in candidates.values():
  if conversation.runtime: conversation.runtime.queue_free()
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_conversations")

func _report_failure(conversation: ConversationSession, result: ActionResult) -> void:
 result.details["encounter_id"] = str(conversation.encounter_id)
 result.details["session_id"] = str(conversation.id)
 push_warning("Narrative stopped: %s (%s)" % [result.message_key,result.details])
 failed.emit(result)

func _context_for(conversation: ConversationSession) -> Dictionary:
 var projected := context(conversation.participants,conversation.context_extra)
 for key in _definitions[str(conversation.encounter_id)].get("context_conditions",{}):
  projected[key] = _session.conditions.permits(_definitions[str(conversation.encounter_id)].context_conditions[key],conversation.participants)
 return projected

func can_talk(visit_id: StringName) -> bool:
 if not _session.visitors.is_available(visit_id): return false
 var visit: VisitState = _session.visitors.visits[str(visit_id)]
 var encounter: StringName = &"amgad" if visit.character_id==&"amgad" else &"visitors"
 for conversation: ConversationSession in sessions.values():
  if str(visit_id) in conversation.participants and (conversation.encounter_id==&"football" or (conversation.encounter_id==encounter and int(conversation.context_extra.get("mode",0))==0)): return false
 return not _select_topic(encounter,PackedStringArray([str(visit_id)]),{}).is_empty()
func _select_topic(encounter: StringName, participants: PackedStringArray, extra: Dictionary) -> Dictionary:
 if participants.is_empty() or not _session.visitors.visits.has(participants[0]): return {}
 return history.select(encounter,_definitions[str(encounter)],_session.visitors.visits[participants[0]],_session,int(extra.get("mode",0)))
func _saved_story(record: Dictionary) -> StoryDefinition:
 var story: StoryDefinition = _stories[_definitions[record.encounter_id].story]
 if record.runtime.get("story_hash")==story.sha256: return story
 # Retain the previous published Ink for already-open choices only. New starts
 # always use current content; no cursor is transplanted into a changed story.
 var archived: Dictionary = _session.config.section("legacy_story_"+str(story.id))
 if archived.is_empty(): return null
 var legacy := StoryDefinition.new()
 legacy.id = story.id
 legacy.raw_json = JSON.stringify(archived,"",true)
 legacy.sha256 = legacy.raw_json.sha256_text()
 return legacy if legacy.sha256==record.runtime.get("story_hash") else null
