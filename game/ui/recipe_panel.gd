class_name RecipePanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _instance_id: StringName
var _rows := VBoxContainer.new()
var _feedback := Label.new()
var _heading := Label.new()
var _progress: Array[Dictionary]=[]
func configure(text: UiText, session: GameSession) -> void:
 _session=session
 _text=text
 theme=text.make_theme()
 anchor_left=0.2
 anchor_right=0.8
 anchor_top=0.2
 anchor_bottom=0.85
 var column := VBoxContainer.new()
 add_child(column)
 column.add_child(_heading)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size.y=160
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 column.add_child(scroll)
 _rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(_rows)
 _feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(_feedback)
 column.add_child(UiText.button(text.text("close"),hide))
 session.workflow.changed.connect(func():if visible:_refresh())
 hide()
func present(instance_id: StringName, _recipes: Array[Dictionary] = []) -> void:
 _instance_id=instance_id
 _refresh()
 show()
func _refresh() -> void:
 for child in _rows.get_children():_rows.remove_child(child);child.queue_free()
 _progress.clear()
 var instance := _session.items.get_item(_instance_id)
 var item_definition := _session.items.definition(StringName(str(instance.get("definition_id",""))))
 _heading.text=_text.text("item_actions_title",{"item":item_definition.get("label","")})
 if not instance.is_empty() and _session.items.definition(StringName(instance.definition_id)).get("surface",false):
  var slot := StringName(str(_instance_id)+":top")
  if not _session.inventory.held_id().is_empty():_rows.add_child(UiText.button(_text.text("surface_put"),func():_session.hygiene.interrupt_clean();_apply(_session.inventory.put_down(slot))))
  elif not _session.items.items_in(slot).is_empty():_rows.add_child(UiText.button(_text.text("surface_take"),func():_session.hygiene.interrupt_clean();_apply(_session.inventory.pick_up(slot))))
 var station := _session.cooking.job(_instance_id)
 if station!=null and station.stage==&"EMPTY" and station.recipe.rules_id==&"tea":_rows.add_child(UiText.button(_text.text("change_sugar"),func():_apply(_session.cooking.cycle_sugar(_instance_id))))
 var hygiene := _session.hygiene.state(_instance_id)
 if not hygiene.is_empty():
  _rows.add_child(UiText.label(str(hygiene.label)))
  _rows.add_child(UiText.button(_text.text("clean_item"),func():_apply(_session.hygiene.begin_clean(_instance_id))))
  if _session.hygiene.is_cleaning(_instance_id):_rows.add_child(UiText.button(_text.text("clean_stop"),func():_session.hygiene.interrupt_clean();_refresh()))
 for job in _session.workflow.jobs_at(_instance_id):
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  _rows.add_child(UiText.label(str(job.definition.label)+" — "+str(step.label)))
  var progress := UiText.label()
  _rows.add_child(progress)
  _progress.append({"job_id":job.id,"label":progress})
  var id := StringName(job.id)
  var action := StringName(step.action)
  _rows.add_child(UiText.button(step.label,func():_apply(_session.workflow.act(id,action))))
  if step.kind=="batch_heat":_rows.add_child(UiText.button(_text.text("recipe_stop_heat"),func():_apply(_session.workflow.act(id,&"stop_heat"))))
  _rows.add_child(UiText.button(_text.text("recipe_cancel"),func():_apply(_session.workflow.act(id,&"cancel"))))
 for recipe in _session.workflow.available_recipes(_session.location_id,_instance_id):
  var definition: Dictionary=recipe.definition
  _rows.add_child(UiText.label(definition.label))
  var requirements := PackedStringArray()
  for input in definition.inputs:requirements.append(str(_session.items.definition(StringName(input.definition_id)).label)+" × "+str(input.quantity))
  var detail := UiText.label(" · ".join(requirements))
  detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  _rows.add_child(detail)
  if not recipe.available:
   var reason := ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,recipe.missing,recipe.details)
   var missing := UiText.label(_text.text("recipe_missing",{"reason":_text.outcome(reason)}))
   missing.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   _rows.add_child(missing)
  var id := StringName(recipe.id)
  var button := UiText.button(_text.text("recipe_start"),func():_apply(_session.workflow.start(id,_session.location_id,PackedStringArray([str(_instance_id)]))))
  button.disabled=not recipe.available
  _rows.add_child(button)
func _apply(result: ActionResult) -> void:
 _feedback.text=_text.outcome(result)
 _refresh()
func _process(_delta: float) -> void:
 if not visible:return
 for entry in _progress:
  var job := _session.workflow.job(StringName(entry.job_id))
  if job.is_empty():continue
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  var value := _text.text("recipe_progress",{"elapsed":"%.1f" % job.elapsed,"duration":step.duration})
  if step.kind=="batch_heat":
   var batch := _session.items.get_item(StringName(str(job.get("bowl_id",""))))
   value+=" · "+_text.text("recipe_portions",{"count":batch.get("attributes",{}).get("portions_remaining",0)})
  entry.label.text=value
