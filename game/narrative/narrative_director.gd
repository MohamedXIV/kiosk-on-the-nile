class_name NarrativeDirector
extends Node
var history := ConversationHistory.new()
signal chapter_finished(id: StringName, reason: StringName)
signal changed
signal failed(result: ActionResult)
var sessions: Dictionary = {}
var _stories: Dictionary = {}
var _definitions: Dictionary
var _session: GameSession
var _next: int = 1
var _focus: StringName
var _opening: Dictionary = {}
var _pending_choices: Dictionary = {}
var _manual_opening: bool = false
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
 var pending := _session.service.pending_for(StringName(participants[0])) if not participants.is_empty() else null
 if pending!=null:intended_food=str(pending.food_id)
 var quality: String = _session.visitors.memory.last_served_quality
 var recipe: Dictionary = _session.config.section("recipes").recipes.tea
 for i in range(recipe.quality_keys.size()):
  if recipe.quality_keys[i] == quality: quality = recipe.quality_names[str(i)]
 var data := {"day":_session.clock.day,"amgad_visits":_session.visitors.memory.amgad_visits,"last_served_quality":quality if not quality.is_empty() else "مظبوط","known_cheap_fan":_session.knowledge.has(&"KNOWN_CHEAP_FAN"),"familiarity":_session.relationships.value(&"player",StringName(character_id),&"familiarity"),"character_id":character_id,"fan_price_label":String.num(float(_session.config.section("balance").fan_price)/100.0,2),"familiar":_session.relationships.value(&"player",StringName(character_id),&"familiarity")>=float(_session.config.section("social").conversation_familiarity_threshold),"kiosk_open":_session.kiosk_open,"request_can_prepare":_session.request_can_prepare(StringName(intended_food)),"mode":0,"quality_score":0,"order_label":_session.foods.definition(StringName(intended_food)).get("menu_label","")}
 var visit: VisitState = _session.visitors.visits.get(participants[0]) if not participants.is_empty() else null
 var previous := _session.visitors.history.previous_service(character_id,visit.id) if visit else {}
 data.merge({"topic_id":"","line_variant":0,"hour":int(_session.clock.minutes)/60,"bought_fan":_session.home.has_fan,"visit_count":_session.visitors.visit_count(StringName(character_id)),"previous_quality":int(previous.get("quality",-1)),"previous_food":str(previous.get("food_id",""))},true)
 data.merge(extra,true)
 return data
func start(encounter_id: StringName, participants: PackedStringArray, extra: Dictionary = {}) -> ActionResult:
 if encounter_id==&"social_invitation" and _session.personal.active():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_busy")
 var definition: Dictionary = _definitions.get(str(encounter_id),{})
 if definition.is_empty() or not _encounter_available(definition,participants): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_unavailable")
 if encounter_id==&"social_invitation" and not _session.actions.preview(&"personal_focus").ok:return _session.actions.preview(&"personal_focus")
 var wants_manual := bool(extra.get("manual_read",definition.get("advancement","automatic")=="manual" and int(extra.get("mode",0))==0))
 if wants_manual and (_manual_opening or not _session.personal.can_acquire(participants)):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_busy")
 var social_topic := str(definition.get("social_topic",""))
 if not social_topic.is_empty():
  if not _session.social_life.topic_available(social_topic) or participants.is_empty():return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"nothing_new_to_say")
  var visit: VisitState=_session.visitors.visits.get(participants[0])
  if visit==null or str(visit.character_id)!=_session.social_life.topic_actor(social_topic):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_unavailable")
 var key := str(encounter_id)+":"+",".join(participants)
 if _opening.has(key): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_opening")
 for existing in sessions.values():
  if not existing.finished and existing.encounter_id==encounter_id and existing.participants==participants and int(existing.context_extra.get("mode",0))==int(extra.get("mode",0)): return ActionResult.success({"session_id":str(existing.id)})
 var selected := _select_topic(encounter_id,participants,extra)
 if definition.has("topics") and selected.is_empty(): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"nothing_new_to_say")
 if definition.get("manual",encounter_id in [&"amgad",&"visitors"]) and int(extra.get("mode",0))==0:
  for existing: ConversationSession in sessions.values():
   if existing.participants==participants and existing.current.choices.is_empty() and existing.encounter_id!=&"football": _finish(existing)
 _opening[key] = true
 if wants_manual:_manual_opening=true
 var conversation := ConversationSession.new()
 conversation.id = StringName("conversation_%d" % _next)
 _next += 1
 conversation.encounter_id = encounter_id
 conversation.participants = participants.duplicate()
 conversation.optional = bool(definition.get("optional",false))
 conversation.topic_selection = selected
 conversation.context_extra = extra.duplicate(true)
 if not selected.is_empty(): conversation.context_extra.merge({"topic_id":selected.topic_id,"line_variant":selected.variant,"source_item_id":selected.get("source_id","")},true)
 if selected.get("source_type")=="visit" and not participants.is_empty():
  conversation.context_extra["experience_context"]=_session.customer_experience.context(StringName(participants[0]))
 conversation.runtime = InkRuntime.new()
 add_child(conversation.runtime)
 var result := await conversation.runtime.open(_stories[definition.story],_context_for(conversation))
 _opening.erase(key)
 if wants_manual:_manual_opening=false
 if not result.ok or not _encounter_available(definition,participants):
  conversation.runtime.queue_free()
  return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"encounter_unavailable")
 sessions[str(conversation.id)] = conversation
 if wants_manual and not _session.personal.adopt(conversation):
  _finish(conversation,&"cancelled")
  return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_busy")
 var advanced := _advance(conversation)
 if not advanced.ok:return advanced
 return ActionResult.success({"session_id":str(conversation.id)})
func tick(delta: float) -> void:
 for conversation: ConversationSession in sessions.values():
  if conversation.finished: continue
  var definition: Dictionary = _definitions[str(conversation.encounter_id)]
  if not _encounter_available(definition,conversation.participants):
   cancel(conversation.id)
   continue
  conversation.elapsed += delta
  if not conversation.current.choices.is_empty():
   conversation.choice_elapsed += delta
   if conversation.optional and conversation.choice_elapsed>=float(definition.get("choice_expiry",8)):
    if not _can_hear(conversation):
     _finish(conversation)
     continue
    var listen := str(int(definition.get("listen_choice",2)))
    choose(conversation.id,StringName("%s:%d:%s" % [conversation.id,conversation.beat,listen]),true)
   elif _focus.is_empty() and _can_offer(conversation): _focus = conversation.id; changed.emit()
  elif manual(conversation):continue
  elif conversation.elapsed>=maxf(conversation.current.duration,0.05):
   if conversation.current.ended: _finish(conversation)
   else: _advance(conversation)
func _can_offer(conversation: ConversationSession) -> bool:
 var definition: Dictionary = _definitions[str(conversation.encounter_id)]
 return _session.conditions.permits(definition.get("offer_requires",{}),conversation.participants)
func _advance(conversation: ConversationSession) -> ActionResult:
 conversation.runtime.set_context(_context_for(conversation))
 conversation.current = conversation.runtime.advance()
 conversation.beat += 1
 conversation.elapsed = 0
 conversation.choice_elapsed = 0
 if not conversation.current.result.ok:
  _report_failure(conversation,conversation.current.result)
  _finish(conversation)
  return conversation.current.result
 var speaker := str(conversation.current.speaker_id)
 if not speaker.is_empty():
  var valid_speaker := false
  for id in conversation.participants:
   if _session.visitors.visits.has(id) and str(_session.visitors.visits[id].character_id)==speaker: valid_speaker=true
  if not valid_speaker:
   var rejected := ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_story_speaker")
   _report_failure(conversation,rejected)
   _finish(conversation)
   return rejected
 for effect in conversation.current.effects:
  if not _session.effects.valid(effect):
   var rejected := ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_narrative_effect")
   _report_failure(conversation,rejected)
   _finish(conversation)
   return rejected
 for i in range(conversation.current.effects.size()):
  if not _can_hear(conversation):continue
  var applied := _session.effects.apply(conversation.current.effects[i],StringName("%s/%d/%d" % [conversation.id,conversation.beat,i]),speaker,conversation.participants)
  if not applied.ok:
   _report_failure(conversation,applied)
   _finish(conversation)
   return applied
 if _pending_choices.has(str(conversation.id)):
  if _can_hear(conversation):_session.journal.append_once(_pending_choices[str(conversation.id)])
  _pending_choices.erase(str(conversation.id))
 if not conversation.current.text.is_empty() and _can_hear(conversation):
  history.commit(conversation.topic_selection)
  _journal_line(conversation)
  _session.social_life.heard(speaker)
  if conversation.encounter_id!=&"social_invitation" or conversation.context_extra.get("invitation_listening",false):
   var topic := str(_definitions[str(conversation.encounter_id)].get("social_topic",conversation.context_extra.get("topic_id","")))
   _session.social_life.heard_topic(topic)
 if _focus.is_empty() and (manual(conversation) or not conversation.current.choices.is_empty()) and _can_offer(conversation): _focus = conversation.id
 changed.emit()
 return ActionResult.success()
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
 if not _encounter_available(definition,conversation.participants): return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"stale_choice")
 var candidates: Array = choices(conversation)
 if automatic and conversation.optional: candidates = conversation.current.choices.map(func(choice):return {"id":str(conversation.choice_id(choice)),"index":choice.index})
 for choice in candidates:
  if choice.id != str(choice_id): continue
  var becomes_manual := manual(conversation) or (conversation.encounter_id==&"social_invitation" and int(choice.index)==0)
  if conversation.encounter_id==&"social_invitation" and int(choice.index)==0 and not _session.actions.preview(&"personal_focus").ok:
   return _session.actions.preview(&"personal_focus")
  if becomes_manual and (_manual_opening or not _session.personal.can_acquire(conversation.participants,conversation.id)):
   if automatic:_finish(conversation,&"cancelled")
   return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_busy")
  conversation.runtime.set_context(_context_for(conversation))
  var result := conversation.runtime.choose(int(choice.index))
  if not result.ok: return result
  if _can_hear(conversation) and not automatic:
   _pending_choices[str(conversation.id)]={"id":"%s/%d/choice" % [conversation.id,conversation.beat],"chapter":str(conversation.id),"actor":"player","name":str(_session.config.section("ui").get("player_name","أنا")),"text":str(conversation.current.choices[int(choice.index)].text),"channel":"choice","at":_session.clock.world_minutes}
  if conversation.encounter_id==&"social_invitation":
   conversation.optional=false
   conversation.context_extra["invitation_answered"]=true
   conversation.context_extra["invitation_listening"]=int(choice.index)==0
   if int(choice.index)==0:conversation.context_extra["manual_read"]=true
  if manual(conversation) and not _session.personal.adopt(conversation):
   _finish(conversation,&"cancelled")
   return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_busy")
  if _focus==session_id: _focus = &""
  var advanced := _advance(conversation)
  return ActionResult.success({"cue":"chime"}) if advanced.ok else advanced
 return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"stale_choice")
func focused_session() -> ConversationSession:
 var conversation: ConversationSession = sessions.get(str(_focus))
 if conversation and not conversation.finished and _can_offer(conversation): return conversation
 _focus = &""
 return null
func cancel(session_id: StringName) -> void:
 var conversation: ConversationSession = sessions.get(str(session_id))
 if conversation: _finish(conversation,&"cancelled")
func _finish(conversation: ConversationSession, reason: StringName = &"completed") -> void:
 _pending_choices.erase(str(conversation.id))
 conversation.finished = true
 if conversation.encounter_id==&"service_availability" and not conversation.participants.is_empty():_session.visitors.reset_request(StringName(conversation.participants[0]))
 sessions.erase(str(conversation.id))
 if conversation.runtime:
  conversation.runtime.close()
  conversation.runtime.queue_free()
  conversation.runtime = null
 if _focus==conversation.id: _focus = &""
 chapter_finished.emit(conversation.id,reason)
 changed.emit()
func cancel_all() -> void:
 for conversation in sessions.values():
  if not conversation.finished: _finish(conversation,&"cancelled")
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
  conversation.optional = bool(_definitions[record.encounter_id].get("optional",false)) and not conversation.context_extra.get("invitation_answered",false)
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
   if not ConversationHistory.equivalent_selection(restored_history.select(conversation.encounter_id,_definitions[str(conversation.encounter_id)],selected_visit,_session,int(conversation.context_extra.get("mode",0))),conversation.topic_selection): return _reject_candidates(candidates)
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
 var social_topic := str(_definitions[str(conversation.encounter_id)].get("social_topic",conversation.context_extra.get("topic_id","")))
 if not social_topic.is_empty() and str(conversation.encounter_id).begins_with("social_"):
  projected.merge(_session.social_life.dialogue_context(social_topic),true)
 var experience: Dictionary=conversation.context_extra.get("experience_context",{})
 if not experience.is_empty():
  var food := _session.foods.definition(StringName(str(experience.get("previous_food_id",""))))
  projected.merge({"venue_dirty_category":str(experience.get("dirty_category","")),"venue_previous_food":str(food.get("menu_label","الأكل")),"venue_previous_quality":int(experience.get("previous_food_quality",-1))},true)
 var learning_recipe := str(_definitions[str(conversation.encounter_id)].get("learning_recipe",""))
 if not learning_recipe.is_empty():
  var knowledge := _session.learning.context(StringName(learning_recipe))
  var source := _session.learning.result_evidence(StringName(str(conversation.context_extra.get("source_item_id",""))))
  projected.merge({"shawarma_attempted":knowledge.attempted,"shawarma_completed":knowledge.completed,"shawarma_quality":int(source.get("quality",knowledge.last_quality))},true)
 for key in _definitions[str(conversation.encounter_id)].get("context_conditions",{}):
  projected[key] = _session.conditions.permits(_definitions[str(conversation.encounter_id)].context_conditions[key],conversation.participants)
 return projected

func _encounter_available(definition: Dictionary, participants: PackedStringArray) -> bool:
 if not _session.conditions.permits(definition.get("requires",{}),participants):return false
 if definition.get("requires_pending_order",false):
  if participants.is_empty():return false
  for id in participants:
   if _session.service.pending_for(StringName(id))==null:return false
 return true
func speech_active(visit_id: StringName) -> bool:
 if _session.personal!=null and _session.personal.holds_visit(visit_id):return true
 for conversation: ConversationSession in sessions.values():
  if not conversation.finished and str(visit_id) in conversation.participants and (manual(conversation) or not conversation.current.choices.is_empty() or conversation.elapsed<conversation.current.duration):return true
 return false
func can_talk(visit_id: StringName) -> bool:
 if speech_active(visit_id):return false
 if not _session.visitors.is_available(visit_id): return false
 var visit: VisitState = _session.visitors.visits[str(visit_id)]
 for conversation: ConversationSession in sessions.values():
  if str(visit_id) in conversation.participants and (conversation.encounter_id==&"football" or int(conversation.context_extra.get("mode",0))==0):return false
 return not talk_encounter(visit_id).is_empty()
func talk_encounter(visit_id: StringName) -> StringName:
 var visit: VisitState=_session.visitors.visits.get(str(visit_id))
 if visit==null:return &""
 var fallback: Array=["amgad"] if visit.character_id==&"amgad" else ["visitors"]
 var encounters: Array=_session.visitors.character(visit.character_id).get("manual_encounters",fallback)
 for id in encounters:
  if not _select_topic(StringName(id),PackedStringArray([str(visit_id)]),{}).is_empty():return StringName(id)
 return &""
func _select_topic(encounter: StringName, participants: PackedStringArray, extra: Dictionary) -> Dictionary:
 if participants.is_empty() or not _session.visitors.visits.has(participants[0]): return {}
 return history.select(encounter,_definitions[str(encounter)],_session.visitors.visits[participants[0]],_session,int(extra.get("mode",0)),str(extra.get("requested_topic","")))
func _saved_story(record: Dictionary) -> StoryDefinition:
 var story: StoryDefinition = _stories[_definitions[record.encounter_id].story]
 if record.runtime.get("story_hash")==story.sha256: return story
 var section: String=_session.config.section("story_archive").get(str(story.id),{}).get(str(record.runtime.get("story_hash","")),"")
 if not section.is_empty():
  var saved := StoryDefinition.new()
  saved.id=story.id
  saved.raw_json=JSON.stringify(_session.config.section(section),"",true)
  saved.sha256=saved.raw_json.sha256_text()
  if saved.sha256==record.runtime.get("story_hash"):return saved
 # Retain the previous published Ink for already-open choices only. New starts
 # always use current content; no cursor is transplanted into a changed story.
 var archived: Dictionary = _session.config.section("legacy_story_"+str(story.id))
 if archived.is_empty(): return null
 var legacy := StoryDefinition.new()
 legacy.id = story.id
 legacy.raw_json = JSON.stringify(archived,"",true)
 legacy.sha256 = legacy.raw_json.sha256_text()
 return legacy if legacy.sha256==record.runtime.get("story_hash") else null

func _can_hear(conversation: ConversationSession) -> bool:
 if not _session.locations.is_physical(_session.location_id):return false
 var radius := float(_session.config.section("spatial").hearing_radius)
 for participant in conversation.participants:
  var visit: VisitState=_session.visitors.visits.get(str(participant))
  if visit!=null and visit.pose.location_id==_session.location_id and visit.pose.ground.distance_to(_session.player_ground)<=radius:return true
 return false

func has_topics(encounter: StringName, participants: PackedStringArray, extra: Dictionary) -> bool:
 return not _select_topic(encounter,participants,extra).is_empty()

func manual(conversation: ConversationSession) -> bool:
 if conversation.encounter_id==&"social_invitation" and conversation.context_extra.get("invitation_listening",false):return true
 if conversation.context_extra.has("manual_read"):return bool(conversation.context_extra.manual_read)
 return _definitions[str(conversation.encounter_id)].get("advancement","automatic")=="manual" and int(conversation.context_extra.get("mode",0))==0
func advance_manual(id: StringName) -> ActionResult:
 var conversation: ConversationSession=sessions.get(str(id))
 if conversation==null or not manual(conversation) or not _can_hear(conversation) or not _encounter_available(_definitions[str(conversation.encounter_id)],conversation.participants):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_unavailable")
 if not conversation.current.choices.is_empty():return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"choose_a_reply")
 if conversation.current.ended:_finish(conversation)
 else:return _advance(conversation)
 return ActionResult.success()
func _journal_line(conversation: ConversationSession) -> void:
 var actor := str(conversation.current.speaker_id)
 if actor.is_empty():return
 _session.journal.append_once({"id":"%s/%d/speech" % [conversation.id,conversation.beat],"chapter":str(conversation.id),"actor":actor,"name":str(_session.visitors.character(StringName(actor)).get("name",actor)),"text":conversation.current.text,"channel":"speech","at":_session.clock.world_minutes})
func available_for(conversation: ConversationSession) -> bool:
 return _encounter_available(_definitions[str(conversation.encounter_id)],conversation.participants)
func manual_topics_for(visit_id: StringName) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 var visit: VisitState=_session.visitors.visits.get(str(visit_id))
 if visit==null or not _session.visitors.is_available(visit_id):return result
 for topic in _session.social_life.topics_for(visit_id):result.append({"key":"social:"+str(topic.id),"label":str(topic.label),"encounter":str(topic.encounter),"topic":""})
 var ids: Array=_session.visitors.character(visit.character_id).get("manual_encounters",["amgad"] if visit.character_id==&"amgad" else ["visitors"])
 for encounter in ids:
  for topic in _definitions[encounter].get("topics",[]):
   var selected := history.select(StringName(encounter),_definitions[encounter],visit,_session,0,str(topic.id))
   if not selected.is_empty():result.append({"key":str(encounter)+"/"+str(topic.id),"label":str(topic.get("label","نكمل كلامنا")),"encounter":str(encounter),"topic":str(topic.id)})
 if _session.service.pending_for(visit_id)!=null:result.append({"key":"order_recall","label":str(_session.config.section("ui").recall_order),"encounter":"orders","topic":""})
 return result
func start_manual_topic(visit_id: StringName, key: String) -> ActionResult:
 for topic in manual_topics_for(visit_id):
  if topic.key!=key:continue
  if key=="order_recall":
   return await start(&"orders",PackedStringArray([str(visit_id)]),{"mode":6,"line_variant":_session.visitors.random_index(3),"manual_read":true})
  return await start(StringName(topic.encounter),PackedStringArray([str(visit_id)]),{"requested_topic":str(topic.topic),"manual_read":true})
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"nothing_new_to_say")
func validate_paused(record: Dictionary) -> ActionResult:
 if not _definitions.has(record.get("encounter_id")) or not ContentValidation.integer(record.get("beat")) or record.beat<1 or not ContentValidation.number(record.get("elapsed")) or record.elapsed<0 or not ContentValidation.number(record.get("choice_elapsed")) or record.choice_elapsed<0 or not record.get("topic_selection") is Dictionary:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_paused_conversation")
 if not valid_sequence(str(record.id),"conversation_",_next):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_paused_conversation")
 if not record.topic_selection.is_empty():
  var validation := ConversationHistory.new().restore({record.topic_selection.get("key",""):record.topic_selection},_definitions,_session.config.section("visitors").characters)
  if not validation.ok:return validation
 var story := _saved_story(record)
 if story==null:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"incompatible_story")
 var runtime := InkRuntime.new()
 add_child(runtime)
 var result := await runtime.open(story,{})
 if result.ok:result=runtime.restore(record.runtime)
 if result.ok:
  for effect in runtime.frame().effects:
   if not _session.effects.valid(effect):result=ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_narrative_effect")
 runtime.close()
 runtime.queue_free()
 return result
func resume_record(record: Dictionary, visit_id: StringName) -> ActionResult:
 var result := await validate_paused(record)
 if not result.ok:return result
 var conversation := ConversationSession.new()
 conversation.id=StringName(record.id)
 conversation.encounter_id=StringName(record.encounter_id)
 conversation.participants=PackedStringArray([str(visit_id)])
 conversation.context_extra=record.context_extra.duplicate(true)
 conversation.context_extra["manual_read"]=true
 conversation.topic_selection=record.topic_selection.duplicate(true)
 conversation.beat=int(record.beat)
 conversation.elapsed=float(record.elapsed)
 conversation.choice_elapsed=float(record.choice_elapsed)
 if not available_for(conversation):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"conversation_unavailable")
 conversation.runtime=InkRuntime.new()
 add_child(conversation.runtime)
 result=await conversation.runtime.open(_saved_story(record),_context_for(conversation))
 if result.ok:result=conversation.runtime.restore(record.runtime)
 if not result.ok:
  conversation.runtime.queue_free()
  return result
 conversation.current=conversation.runtime.frame()
 sessions[str(conversation.id)]=conversation
 _focus=conversation.id
 changed.emit()
 return ActionResult.success({"session_id":str(conversation.id)})

func valid_sequence(id: String, prefix: String, limit: int) -> bool:
 var suffix := id.trim_prefix(prefix)
 return id.begins_with(prefix) and suffix.is_valid_int() and int(suffix)>0 and suffix==str(int(suffix)) and int(suffix)<limit
func validate_sequences() -> ActionResult:
 for id in sessions:
  if not valid_sequence(str(id),"conversation_",_next):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_conversation_sequence")
 var references: Array=[]
 references.append_array(_session.effects.snapshot().applied.keys())
 for fact in _session.knowledge.snapshot().facts.values():
  if str(fact.source).begins_with("conversation_"):references.append(fact.source)
 for receipt in _session.social_life.snapshot().receipts.values():
  if str(receipt.source).begins_with("conversation_"):references.append(receipt.source)
 for e in _session.journal.entries():
  if e.channel not in ["speech","choice"]:continue
  var parts := str(e.id).split("/")
  if parts.size()!=3 or parts[0]!=e.chapter or parts[2]!=e.channel or not valid_sequence(parts[0],"conversation_",_next) or not parts[1].is_valid_int() or int(parts[1])<1 or parts[1]!=str(int(parts[1])) or (e.channel=="choice" and e.actor!="player"):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_journal_sequence")
 for reference in references:
  var parts := str(reference).split("/")
  if parts.size()!=3 or not valid_sequence(parts[0],"conversation_",_next) or not parts[1].is_valid_int() or int(parts[1])<1 or not parts[2].is_valid_int() or int(parts[2])<0:return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_effect_sequence")
 return ActionResult.success()
