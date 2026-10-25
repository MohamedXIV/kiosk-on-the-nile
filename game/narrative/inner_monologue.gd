class_name InnerMonologue
extends Node
## Each authored thought is one completed Ink frame: no hidden dialogue cursor.
var _session: GameSession
var _rules: Array=[]
var _next: int=1
var _next_at: float=0
var _heard: Dictionary={}
var _current: Dictionary={}
var _loading: bool=false
func configure(session: GameSession) -> void:
 _session=session
 _rules=session.config.section("narration").thoughts
 _next_at=session.clock.world_minutes+float(session.config.section("narration").thought_delay_minutes)
func tick(frame: Dictionary) -> void:
 if not _current.is_empty():
  _current.remaining=maxf(0,float(_current.remaining)-float(frame.delta))
  if _current.remaining<=0:_current={}
 if _loading or not _current.is_empty() or _session.clock.world_minutes<_next_at or _blocked():return
 for rule in _rules:
  if _heard.has(rule.id) and (rule.once or _session.clock.world_minutes-float(_heard[rule.id])<float(rule.cooldown_minutes)):continue
  if not str(rule.need).is_empty() and float(_session.needs.get(rule.need))>=float(rule.below):continue
  if not _session.conditions.permits(rule.requires):continue
  _speak(rule)
  return
 _next_at=_session.clock.world_minutes+float(_session.config.section("narration").thought_retry_minutes)
func _blocked() -> bool:
 return _session.personal.active() or _session.narrative.focused_session()!=null or not _session.locations.is_physical(_session.location_id) or (_session.social_life.participation_blocked.is_valid() and _session.social_life.participation_blocked.call())
func _speak(rule: Dictionary) -> void:
 _loading=true
 var runtime := InkRuntime.new()
 add_child(runtime)
 var story := StoryDefinition.new()
 story.id=&"inner_monologue"
 story.raw_json=JSON.stringify(_session.config.section("story_inner_monologue"),"",true)
 story.sha256=story.raw_json.sha256_text()
 var result := await runtime.open(story,{"topic_id":str(rule.id)})
 if result.ok and not _blocked():
  var output := runtime.advance()
  if output.result.ok and output.ended and output.choices.is_empty() and output.effects.is_empty() and output.speaker_id==&"player" and not output.text.is_empty():
   var id := "thought_%d" % _next
   _next+=1
   var event := {"id":id,"chapter":id,"actor":"player","name":LocalizedNarrative.speaker("player",_session.tuning.display_name("player",str(_session.config.section("ui").player_name))),"text":LocalizedNarrative.line(output),"channel":"thought","at":_session.clock.world_minutes}
   event.merge(LocalizedNarrative.metadata(output.loc_id,output.loc_args,output.text))
   if _session.journal.append_once(event).ok:
    _current={"id":id,"rule":str(rule.id),"text":event.text,"remaining":output.duration,"loc_id":output.loc_id,"loc_args":output.loc_args.duplicate(true)}
    _heard[rule.id]=_session.clock.world_minutes
    _next_at=_session.clock.world_minutes+float(_session.config.section("narration").thought_delay_minutes)
 runtime.close()
 runtime.queue_free()
 _loading=false
func view() -> Dictionary:
 var value := _current.duplicate(true)
 if value.has("loc_id") and value.loc_id!="":value.text=LocalizedNarrative.resolve(str(value.loc_id),value.get("loc_args",{}),str(value.text))
 return value
func snapshot() -> Dictionary:
 return {"next_id":_next,"next_at":_next_at,"heard":_heard.duplicate(),"current":_current.duplicate(true)}
func restore(data: Dictionary) -> ActionResult:
 if not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not ContentValidation.number(data.get("next_at")) or data.next_at<0 or not data.get("heard") is Dictionary or not data.get("current") is Dictionary:return _fail()
 var ids := _rules.map(func(rule):return str(rule.id))
 for id in data.heard:
  if not id in ids or not ContentValidation.bounded(data.heard[id],0,_session.clock.world_minutes+0.001):return _fail()
 if not data.current.is_empty():
  if not data.current.get("rule") in ids or not data.current.get("id") is String or not data.current.get("text") is String or not ContentValidation.bounded(data.current.get("remaining"),0,120):return _fail()
  if data.current.has("loc_id") and (not data.current.loc_id is String or not data.current.get("loc_args") is Dictionary):return _fail()
  var recorded := _session.journal.event(data.current.id)
  if data.current.get("loc_id","")!="" and (recorded.get("text_ref","")!=data.current.loc_id or recorded.get("parameters",{})!=data.current.loc_args):return _fail()
  if recorded.is_empty() or recorded.channel!="thought" or recorded.text!=data.current.text:return _fail()
 for event in _session.journal.entries({"channel":"thought"}):
  if event.actor!="player" or event.chapter!=event.id or not _session.narrative.valid_sequence(str(event.id),"thought_",int(data.next_id)):return _fail()
 _next=int(data.next_id)
 _next_at=float(data.next_at)
 _heard=data.heard.duplicate()
 _current=data.current.duplicate(true)
 return ActionResult.success()
func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_inner_monologue")
