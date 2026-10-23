class_name InkRuntime
extends Node
## The sole application boundary that depends on inkgd implementation types.
const Player = preload("res://addons/inkgd/ink_player.gd")
const InkData = preload("res://addons/inkgd/editor/import_plugins/ink_resource.gd")
const RuntimeNode = preload("res://addons/inkgd/ink_runtime.gd")
var _player: Node
var _definition: StoryDefinition
var _frame := NarrativeTypes.Frame.new()
var _error: String = ""
func open(definition: StoryDefinition, context: Dictionary) -> ActionResult:
 close()
 _definition = definition
 var json := definition.raw_json if not definition.raw_json.is_empty() else FileAccess.get_file_as_string(definition.compiled_path)
 if not JSON.parse_string(json) is Dictionary or json.sha256_text() != definition.sha256:
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_story")
 if get_tree().root.get_node_or_null("__InkRuntime") == null:
  var engine_runtime = RuntimeNode.new()
  engine_runtime.stop_execution_on_error = false
  engine_runtime.stop_execution_on_exception = false
  get_tree().root.add_child(engine_runtime)
 _player = Player.new()
 _player.loads_in_background = false
 var data = InkData.new()
 data.json = json
 _player.ink_file = data
 _player.error_encountered.connect(func(message, _type): _error = str(message))
 add_child(_player)
 _player.create_story()
 var loaded: bool = await _player.loaded
 if not loaded or not _error.is_empty():
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"story_load_failed")
 set_context(context)
 return ActionResult.success()
func set_context(context: Dictionary) -> void:
 if _player == null: return
 for key in context:
  if _player.get_variable(str(key)) != null:
   _player.set_variable(str(key), context[key])
func advance() -> NarrativeTypes.Frame:
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
   if parts.size() != 2 or not parts[0].strip_edges() in ["speaker", "duration", "effect", "join"]:
    _frame.result = ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"unknown_story_metadata")
    _frame.effects.clear()
    _frame.ended = true
    return _frame
   var key := parts[0].strip_edges()
   var value := parts[1].strip_edges()
   match key:
    "speaker": _frame.speaker_id = StringName(value)
    "duration":
     if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() <= 0:
      _frame.result = ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_line_duration")
      return _frame
     _frame.duration = value.to_float()
    "effect":
     var fields := value.split("|")
     if fields.size() == 2 and fields[0] == "mood" and fields[1].is_valid_float():
      _frame.effects.append({"kind":"mood","amount":fields[1].to_float()})
     elif fields.size()==2 and fields[0]=="service":
      _frame.effects.append({"kind":"service","action_id":fields[1]})
     elif fields.size()==2 and fields[0]=="social":
      _frame.effects.append({"kind":"social","action_id":fields[1]})
     elif fields.size() == 3 and fields[0] == "learn":
      _frame.effects.append({"kind":"learn","fact_id":fields[1],"note":fields[2]})
     else:
      _frame.result = ActionResult.failure(ActionResult.Code.INVALID_CONTENT, &"invalid_story_effect")
      _frame.effects.clear()
      return _frame
 for choice in _player.current_choices:
  _frame.choices.append({"id":str(choice.index),"index":choice.index,"text":choice.text.strip_edges()})
 _frame.ended = not _player.can_continue and _frame.choices.is_empty()
 return _frame
func frame() -> NarrativeTypes.Frame:
 return _frame
func choose(index: int) -> ActionResult:
 if _player == null or index < 0 or index >= _player.current_choices.size():
  return ActionResult.failure(ActionResult.Code.INVALID_CHOICE, &"invalid_choice")
 _player.choose_choice_index(index)
 return ActionResult.success()
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
 var previous: String = _player.get_state()
 _player.set_state(data.ink)
 if not _error.is_empty() or _player.current_choices.size()!=displayed.choices.size():
  _player.set_state(previous)
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_state")
 for i in range(_player.current_choices.size()):
  if _player.current_choices[i].text.strip_edges()!=displayed.choices[i].text or _player.current_choices[i].index!=int(displayed.choices[i].index):
   _player.set_state(previous)
   return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_ink_choices")
 _frame = NarrativeTypes.Frame.from_dict(data.frame)
 return ActionResult.success()
func close() -> void:
 if _player != null:
  _player.destroy()
  _player.queue_free()
  _player = null
 _error = ""
 _frame = NarrativeTypes.Frame.new()
func _exit_tree() -> void:
 close()
