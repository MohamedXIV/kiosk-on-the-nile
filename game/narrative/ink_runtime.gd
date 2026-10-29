class_name InkRuntime
extends Node
## The sole application boundary that depends on inkgd implementation types.
const Player = preload("res://addons/inkgd/ink_player.gd")
const InkData = preload("res://addons/inkgd/editor/import_plugins/ink_resource.gd")
const RuntimeNode = preload("res://addons/inkgd/ink_runtime.gd")
var _cache: InkPlayerCache
var _reusable: bool=false
var _player: Node
var _definition: StoryDefinition
var _frame := NarrativeTypes.Frame.new()
var _error: String = ""
var _context: Dictionary={}
var _policy_choices: Dictionary={}
var _policy_map_valid: bool=true
func _scan_policy_choices(value: Variant, depth: int = 0) -> void:
 if depth>128:_policy_map_valid=false;return
 if value is Array:
  var pending := ""
  for part in value:
   if part is String and part.begins_with("^policy_choice:"):
    var id: String = part.trim_prefix("^policy_choice:").strip_edges()
    if not pending.is_empty() or not id.is_valid_identifier():_policy_map_valid=false
    pending=id
   elif part is Dictionary and part.has("*") and not pending.is_empty():
    if not part["*"] is String or (_policy_choices.has(part["*"]) and _policy_choices[part["*"]]!=pending):_policy_map_valid=false
    else:_policy_choices[part["*"]]=pending
    pending=""
   _scan_policy_choices(part,depth+1)
  if not pending.is_empty():_policy_map_valid=false
 elif value is Dictionary:
  for part in value.values():_scan_policy_choices(part,depth+1)
static func valid_autonomous_story(compiled: Dictionary, fallback: Variant) -> bool:
 # Compiled Ink details stay within this adapter. Check declarations before activation.
 var containers: Variant=compiled.get("root")
 if not containers is Array or containers.is_empty() or not containers[-1] is Dictionary:return false
 var named: Dictionary=containers[-1]
 if not fallback is String or not fallback.is_valid_identifier() or not named.get(fallback) is Array:return false
 return _valid_autonomous_tags(containers,named,0)
static func _valid_autonomous_tags(value: Variant, named: Dictionary, depth: int) -> bool:
 if depth>128:return false
 if value is String and value.begins_with("^autonomous:"):
  var path: String=value.trim_prefix("^autonomous:").strip_edges()
  return path.is_valid_identifier() and named.get(path) is Array
 if value is Array:
  for child in value:
   if not _valid_autonomous_tags(child,named,depth+1):return false
 elif value is Dictionary:
  for child in value.values():
   if not _valid_autonomous_tags(child,named,depth+1):return false
 return true
func open(definition: StoryDefinition, context: Dictionary, cache: InkPlayerCache = null) -> ActionResult:
 var perf := RuntimePerformance.begin()
 var result := await _open(definition,context,cache)
 RuntimePerformance.finish("ink_open_wall:"+str(definition.id),perf)
 return result
func _open(definition: StoryDefinition, context: Dictionary, cache: InkPlayerCache) -> ActionResult:
 close()
 _definition = definition
 _policy_choices={};_policy_map_valid=true
 if definition.raw_json.contains("policy_choice:"):_scan_policy_choices(JSON.parse_string(definition.raw_json))
 if not _policy_map_valid:return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_policy_choice_map")
 var json := definition.raw_json if not definition.raw_json.is_empty() else FileAccess.get_file_as_string(definition.compiled_path)
 if not JSON.parse_string(json) is Dictionary or json.sha256_text() != definition.sha256:
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_story")
 if get_tree().root.get_node_or_null("__InkRuntime") == null:
  var engine_runtime = RuntimeNode.new()
  engine_runtime.stop_execution_on_error = false
  engine_runtime.stop_execution_on_exception = false
  get_tree().root.add_child(engine_runtime)
 _cache=cache
 var key := str(definition.id)+":"+definition.sha256
 if is_instance_valid(_cache):_player=_cache.checkout(key)
 if _player!=null:
  _player.error_encountered.connect(_on_player_error)
  var reset_started := RuntimePerformance.begin()
  _player.reset()
  RuntimePerformance.finish("ink_reset",reset_started)
  _reusable=_error.is_empty()
  if not _reusable:return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"story_load_failed")
  set_context(context)
  return ActionResult.success()
 _player = Player.new()
 _player.loads_in_background = false
 var data = InkData.new()
 data.json = json
 _player.ink_file = data
 _player.error_encountered.connect(_on_player_error)
 if is_instance_valid(_cache):_cache.attach(_player,key)
 else:add_child(_player)
 _player.create_story()
 var loaded: bool = await _player.loaded
 if not loaded or not _error.is_empty():
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"story_load_failed")
 _reusable=true
 set_context(context)
 return ActionResult.success()
func _on_player_error(message, _type) -> void:
 _error=str(message)
func set_context(context: Dictionary) -> void:
 _context=context.duplicate(true)
 if _player == null: return
 for key in context:
  if _player.get_variable(str(key)) != null:
   _player.set_variable(str(key), context[key])
func advance() -> NarrativeTypes.Frame:
 var perf := RuntimePerformance.begin()
 var output := _advance_frame()
 RuntimePerformance.finish("ink_advance",perf)
 return output
func _advance_frame() -> NarrativeTypes.Frame:
 _frame = NarrativeTypes.Frame.new()
 if _player == null:
  _frame.result = ActionResult.failure(ActionResult.Code.NOT_AVAILABLE, &"story_unavailable")
  return _frame
 if _player.can_continue:
  # Ink may yield formatting-only newlines before the next spoken beat.
  # They carry no timing/choice/effect and must not create an invisible 5.5s beat.
  for empty_line in range(256):
   _frame.text = _player.continue_story().strip_edges()
   if not _frame.text.is_empty() or not _player.current_tags.is_empty() or not _player.current_choices.is_empty() or not _player.can_continue:break
   if empty_line==255:
    _frame.result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"empty_story_run")
    return _frame
  for tag in _player.current_tags:
   var parts: PackedStringArray = str(tag).split(":", true, 1)
   if parts.size() != 2 or not parts[0].strip_edges() in ["speaker", "duration", "effect", "join", "loc", "autonomous", "policy_action"]:
    _frame.result = ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"unknown_story_metadata")
    _frame.effects.clear()
    _frame.ended = true
    return _frame
   var key := parts[0].strip_edges()
   var value := parts[1].strip_edges()
   match key:
    "autonomous":
     if not value.is_valid_identifier():
      _frame.result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_autonomous_path")
      return _frame
     _frame.autonomous=value
    "policy_action":
     if not value.is_valid_identifier():
      _frame.result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_policy_action");return _frame
     _frame.policy_action=value
    "loc":
     _frame.loc_id=value
     _frame.loc_args=_context.get("localization_args",{}).duplicate(true)
    "speaker": _frame.speaker_id = StringName(value)
    "duration":
     if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() <= 0:
      _frame.result = ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_line_duration")
      return _frame
     _frame.duration = value.to_float()
    "effect":
     var fields := value.split("|")
     var scope := "hearing"
     if fields.size()>0 and fields[0]=="world":scope="world";fields.remove_at(0)
     if fields.size() == 2 and fields[0] == "mood" and fields[1].is_valid_float():
      _frame.effects.append({"kind":"mood","amount":fields[1].to_float()})
     elif fields.size()==5 and fields[0]=="peer_relation" and fields[4].is_valid_float():
      _frame.effects.append({"kind":"peer_relation","from":fields[1],"to":fields[2],"axis":fields[3],"amount":fields[4].to_float()})
     elif fields.size()==2 and fields[0]=="supply":
      _frame.effects.append({"kind":"supply","action_id":fields[1]})
     elif fields.size()==2 and fields[0]=="finance":
      _frame.effects.append({"kind":"finance","action_id":fields[1]})
     elif fields.size()==2 and fields[0]=="service":
      _frame.effects.append({"kind":"service","action_id":fields[1]})
     elif fields.size()==2 and fields[0]=="home":
      _frame.effects.append({"kind":"home","action_id":fields[1]})
     elif fields.size()==2 and fields[0]=="social":
      _frame.effects.append({"kind":"social","action_id":fields[1]})
     elif fields.size() == 3 and fields[0] == "learn":
      _frame.effects.append({"kind":"learn","fact_id":fields[1],"note":fields[2]})
     else:
      _frame.result = ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_story_effect")
      _frame.effects.clear()
      return _frame
     if scope=="world":_frame.effects[-1]["scope"]="world"
 for choice in _player.current_choices:
  var record := {"id":str(choice.index),"index":choice.index,"text":choice.text.strip_edges()}
  if choice.tags is Array:
   for tag in choice.tags:
    if str(tag).begins_with("loc:"):record["loc_id"]=str(tag).trim_prefix("loc:").strip_edges()
  for tag in choice.tags if choice.tags is Array else []:
   if str(tag).begins_with("policy_choice:"):
    var stable := str(tag).trim_prefix("policy_choice:").strip_edges()
    if not stable.is_valid_identifier() or _frame.choices.any(func(c):return c.get("semantic_id")==stable):
     _frame.result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_policy_choice");return _frame
    record["semantic_id"]=stable
  var mapped: String=str(_policy_choices.get(choice.path_string_on_choice,""))
  if record.get("semantic_id","")!=mapped:
   _frame.result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_policy_choice_map");return _frame
  _frame.choices.append(record)
 if not _frame.autonomous.is_empty() and (not _valid_autonomous_path(_frame.autonomous) or _frame.choices.is_empty()):
  _frame.result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_autonomous_path")
  return _frame
 if not _frame.choices.is_empty():_frame.loc_args=_context.get("localization_args",{}).duplicate(true)
 _frame.ended = not _player.can_continue and _frame.choices.is_empty()
 return _frame
func frame() -> NarrativeTypes.Frame:
 return _frame
func choose(index: int) -> ActionResult:
 if _player == null or index < 0 or index >= _player.current_choices.size():
  return ActionResult.failure(ActionResult.Code.INVALID_CHOICE, &"invalid_choice")
 _player.choose_choice_index(index)
 return ActionResult.success()
func _valid_autonomous_path(path: String) -> bool:
 return _player!=null and path.is_valid_identifier() and _player._story.main_content_container.named_content.has(path)
func continue_autonomously(path: String) -> ActionResult:
 if not _valid_autonomous_path(path):return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_autonomous_path")
 _player.choose_path(path)
 return ActionResult.success() if _error.is_empty() else ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_autonomous_path")
func snapshot() -> Dictionary:
 if _player == null: return {}
 var state: String = _player.get_state()
 var displayed := _frame.to_dict()
 return {"story_id":str(_definition.id),"story_hash":_definition.sha256,"ink":state,"frame":displayed,"state_hash":(state+StableJson.stringify(displayed)).sha256_text()}
func restore(data: Dictionary) -> ActionResult:
 if _player == null or data.get("story_hash") != _definition.sha256 or data.get("story_id") != str(_definition.id) or not data.get("ink") is String or not JSON.parse_string(data.ink) is Dictionary or not data.get("frame") is Dictionary:
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE, &"incompatible_story")
 var state: Dictionary = JSON.parse_string(data.ink)
 if not ContentValidation.integer(state.get("inkSaveVersion")) or not state.get("flows") is Dictionary or state.flows.size()!=1 or not state.get("variablesState") is Dictionary or not state.get("evalStack") is Array or not state.get("visitCounts") is Dictionary or not state.get("turnIndices") is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_state")
 for flow in state.flows.values():
  if not flow is Dictionary or not flow.get("callstack") is Dictionary or not flow.get("outputStream") is Array or not flow.get("currentChoices") is Array: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_flow")
 var displayed: Dictionary = data.frame
 if displayed.has("policy_action") and (not displayed.policy_action is String or not displayed.policy_action.is_valid_identifier()):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_policy_action")
 if displayed.has("autonomous") and (not displayed.autonomous is String or not displayed.autonomous.is_valid_identifier()):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_autonomous_path")
 if displayed.has("loc_id") and (not displayed.loc_id is String or not displayed.get("loc_args") is Dictionary):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_localized_frame")
 if not displayed.get("text") is String or not displayed.get("speaker_id") is String or not ContentValidation.number(displayed.get("duration")) or displayed.duration<=0 or not displayed.get("choices") is Array or not displayed.get("effects") is Array or not displayed.get("ended") is bool: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_frame")
 for choice in displayed.choices:
  if not choice is Dictionary or not choice.get("id") is String or not choice.get("text") is String or not ContentValidation.integer(choice.get("index")): return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_choice")
 for effect in displayed.effects:
  if not effect is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_effect")
 var valid_hash: bool = data.get("state_hash")== (data.ink+StableJson.stringify(displayed)).sha256_text()
 if not valid_hash:
  # Legacy frames serialized choice indexes as integers and durations/effects
  # as floats. Recover those declared types before checking the old hash.
  var legacy := displayed.duplicate(true)
  legacy.duration = float(legacy.duration)
  for choice in legacy.choices: choice.index=int(choice.index)
  for effect in legacy.effects:
   if effect.get("kind")=="mood" and ContentValidation.number(effect.get("amount")): effect.amount=float(effect.amount)
  valid_hash = data.get("state_hash")== (data.ink+JSON.stringify(legacy,"",true)).sha256_text()
 if not valid_hash: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"corrupt_story_state")
 if displayed.has("autonomous") and (displayed.choices.is_empty() or not _valid_autonomous_path(displayed.autonomous)):return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_autonomous_path")
 var previous: String = _player.get_state()
 _player.set_state(data.ink)
 if not _error.is_empty() or _player.current_choices.size()!=displayed.choices.size():
  _player.set_state(previous)
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_state")
 var actual_action := ""
 for tag in _player.current_tags:
  if str(tag).begins_with("policy_action:"):actual_action=str(tag).trim_prefix("policy_action:").strip_edges()
 if displayed.get("policy_action","")!=actual_action:
  _player.set_state(previous);return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_policy_action")
 for i in range(_player.current_choices.size()):
  var actual_choice: String=str(_policy_choices.get(_player.current_choices[i].path_string_on_choice,""))
  if displayed.choices[i].get("semantic_id","")!=actual_choice:
   _player.set_state(previous);return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_policy_choice")
  if _player.current_choices[i].text.strip_edges()!=displayed.choices[i].text or _player.current_choices[i].index!=int(displayed.choices[i].index):
   _player.set_state(previous)
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_choices")
 _frame = NarrativeTypes.Frame.from_dict(data.frame)
 return ActionResult.success()
func close() -> void:
 if is_instance_valid(_player):
  if _player.error_encountered.is_connected(_on_player_error):_player.error_encountered.disconnect(_on_player_error)
  if is_instance_valid(_cache):_cache.release(_player,_reusable and _error.is_empty())
  else:
   _player.destroy()
   _player.queue_free()
 _player=null
 _cache=null
 _reusable=false
 _context={}
 _error = ""
 _frame = NarrativeTypes.Frame.new()
func _exit_tree() -> void:
 close()
