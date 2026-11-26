class_name RecipePanel
extends PanelContainer
var _session: GameSession
var _text: UiText
var _instance_id: StringName
var _heading := SheetControls.label()
var _held := SheetControls.label()
var _station_art: ItemGlyph
var _station_summary: PanelContainer
var _station_row: HBoxContainer
var _header: HBoxContainer
var _manage: Button
var _active_feedback: Label
var _gameplay_mode: bool=false
var _tabs := TabContainer.new()
var _care := VBoxContainer.new()
var _active := VBoxContainer.new()
var _recipes := VBoxContainer.new()
var _scrolls: Array[ScrollContainer]=[]
var _feedback := SheetControls.label()
var _cleanliness: Label
var _clean_progress: Label
var _clean_button: Button
var _stop_button: Button
var _progress: Array[Dictionary]=[]
var _selected_ingredients: Dictionary={}
var _serving_options: Dictionary={}
var _last_result: ActionResult
var _hygiene_data: Dictionary
var _dirty: bool=true
var _elapsed: float=0
const COMPACT_WIDTH := 740.0
const COMPACT_STATION_SIZE := 40.0
const REGULAR_STATION_SIZE := 64.0
func configure(text: UiText, session: GameSession) -> void:
 _session=session;_text=text;theme=text.make_theme();_hygiene_data=session.config.section("hygiene")
 SheetControls.shell(self)
 theme_type_variation="CookingBoard"
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",10);add_child(column)
 resized.connect(func():column.add_theme_constant_override("separation",5 if CozyTheme.compact_for(get_viewport_rect().size) else 10))
 SheetControls.header(column,_heading,text,hide,"hunger","SectionClay")
 _header=_heading.get_parent() as HBoxContainer
 _manage=SheetControls.button(UiText.localized("cozy.station_management_short"),func():_tabs.current_tab=2 if _recipes.get_meta("has_recipes",false) else 0)
 _manage.custom_minimum_size=Vector2(96,44)
 _header.add_child(_manage)
 _header.move_child(_manage,_header.get_child_count()-2)
 _manage.hide()
 var hands := PanelContainer.new();hands.theme_type_variation="StationStatus";column.add_child(hands)
 _station_summary=hands
 var station_row := HBoxContainer.new();hands.add_child(station_row)
 _station_row=station_row
 _station_art=ItemGlyph.new();_station_art.custom_minimum_size=Vector2.ONE*REGULAR_STATION_SIZE;station_row.add_child(_station_art)
 resized.connect(_fit_station_art)
 station_row.add_child(_held)
 _tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(_tabs)
 _tabs.get_tab_bar().theme_type_variation="NotebookTabs"
 for rows in [_care,_active,_recipes]:
  var scroll := SheetControls.scroll(rows);_scrolls.append(scroll);_tabs.add_child(scroll)
 column.add_child(_feedback)
 _tabs.tab_changed.connect(func(_tab):_sync_surface())
 clip_contents=true
 session.workflow.changed.connect(func():_dirty=true)
 session.items.changed.connect(func(_revision):_dirty=true)
 session.cooking.changed.connect(func(_id):_dirty=true)
 LocaleService.current.changed.connect(_refresh_language)
 _refresh_language()
 hide()
func _fit_station_art() -> void:
 if not is_instance_valid(_station_art):return
 _station_art.custom_minimum_size=Vector2.ONE*(32.0 if _gameplay_mode else COMPACT_STATION_SIZE if CozyTheme.compact_for(get_viewport_rect().size) else REGULAR_STATION_SIZE)

func _refresh_language() -> void:
 for i in range(3):_tabs.set_tab_title(i,ItemText.t(["care","active","recipes"][i]))
 _manage.text=UiText.localized("cozy.station_management_short")
 _dirty=true
func present(instance_id: StringName, _unused_recipes: Array[Dictionary] = []) -> void:
 var changed_target := _instance_id!=instance_id
 _instance_id=instance_id
 if changed_target:
  _last_result=null
  for scroll in _scrolls:scroll.get_v_scroll_bar().value=0
 _refresh()
 if not _progress.is_empty():_tabs.current_tab=1
 elif changed_target:_tabs.current_tab=2 if _recipes.has_meta("has_recipes") and _recipes.get_meta("has_recipes") else 0
 _sync_surface()
 show()
func _sync_surface() -> void:
 # Explicit management tabs may be large. The active-job tab never is.
 _gameplay_mode=_tabs.current_tab==1
 set_meta("gameplay_overlay",_gameplay_mode)
 _tabs.tabs_visible=not _gameplay_mode
 _station_summary.visible=not _gameplay_mode
 _manage.visible=_gameplay_mode
 var art_parent: Control=_header if _gameplay_mode else _station_row
 if _station_art.get_parent()!=art_parent:
  _station_art.reparent(art_parent,false)
  art_parent.move_child(_station_art,0)
 for child in _header.get_children():
  if child is TextureRect:child.visible=not _gameplay_mode
 if _gameplay_mode:
  _heading.add_theme_font_size_override("font_size",16)
  _heading.text=ItemText.definition(_session,str(_session.items.get_item(_instance_id).get("definition_id","")))
 else:
  _heading.remove_theme_font_size_override("font_size")
  _heading.text=_text.text("item_actions_title",{"item":ItemText.definition(_session,str(_session.items.get_item(_instance_id).get("definition_id","")))})
 _feedback.visible=not _gameplay_mode and not _feedback.text.is_empty()
 if is_instance_valid(_active_feedback):_active_feedback.visible=_gameplay_mode and not _active_feedback.text.is_empty()
 _fit_station_art()
 SheetControls._queue_sheet_fit(weakref(self),1100,122,18)

func _refresh() -> void:
 _dirty=false
 var focus_key := _focused_key()
 var offsets: Array=[]
 for scroll in _scrolls:offsets.append(scroll.get_v_scroll_bar().value)
 _progress.clear()
 _recipes.set_meta("has_recipes",false)
 for rows in [_care,_active,_recipes]:SheetControls.clear(rows)
 _cleanliness=null;_clean_progress=null;_clean_button=null;_stop_button=null;_active_feedback=null
 var instance := _session.items.get_item(_instance_id)
 var placement := _session.spaces.placement(_instance_id)
 var definition_id := str(instance.get("definition_id",""))
 _station_art.visible=not instance.is_empty()
 _station_art.configure(_session.items.definition(StringName(definition_id)),definition_id)
 _heading.text=_text.text("item_actions_title",{"item":ItemText.definition(_session,str(instance.get("definition_id","")))})
 var held := _session.items.get_item(_session.inventory.held_id())
 _held.text=ItemText.t("held",{"item":ItemText.instance(_session,held)}) if not held.is_empty() else ItemText.t("hands_empty")
 if instance.is_empty() or placement.get("location_id","")!=str(_session.location_id):
  for rows in [_care,_active,_recipes]:rows.add_child(SheetControls.label(ItemText.t("station_gone")))
  _tabs.current_tab=0
 else:
  _render_care(instance)
  _render_jobs()
  _render_recipes()
 _feedback.text=ItemText.missing(_session,_text,_last_result) if _last_result else ""
 _active_feedback=SheetControls.label(_feedback.text)
 _active.add_child(_active_feedback)
 _active.move_child(_active_feedback,0)
 _sync_surface()
 for i in range(_scrolls.size()):_scrolls[i].get_v_scroll_bar().set_deferred("value",offsets[i])
 _update_progress()
 _restore_focus(focus_key)
func _render_care(instance: Dictionary) -> void:
 var definition := _session.items.definition(StringName(instance.definition_id))
 if definition.get("surface",false):
  var slot := StringName(str(_instance_id)+":top")
  if not _session.inventory.held_id().is_empty():_care.add_child(_action(_text.text("surface_put"),"surface_put",func():_session.hygiene.interrupt_clean();_apply(_session.inventory.put_down(slot))))
  elif not _session.items.items_in(slot).is_empty():_care.add_child(_action(_text.text("surface_take"),"surface_take",func():_session.hygiene.interrupt_clean();_apply(_session.inventory.pick_up(slot))))
 var station := _session.cooking.job(_instance_id)
 if station!=null and station.stage==&"EMPTY" and station.recipe.rules_id==&"tea":
  var sugar_source := ""
  for sugar in station.recipe.data.sugars:
   if str(sugar.id)==str(station.sugar_id):sugar_source=str(sugar.label)
  _care.add_child(SheetControls.label(ItemText.t("sugar",{"name":ItemText.source("food.tea.sugar."+str(station.sugar_id),sugar_source)})))
  _care.add_child(_action(_text.text("change_sugar"),"sugar",func():_apply(_session.cooking.cycle_sugar(_instance_id))))
 var hygiene := _session.hygiene.state(_instance_id)
 if not hygiene.is_empty():
  var card := SheetControls.card(_care)
  _cleanliness=SheetControls.label();SheetControls.title(_cleanliness);card.add_child(_cleanliness)
  _clean_progress=SheetControls.label();SheetControls.muted(_clean_progress);card.add_child(_clean_progress)
  var actions := SheetControls.columns(card,540)
  _clean_button=_action(_text.text("clean_item"),"clean",func():_apply(_session.hygiene.begin_clean(_instance_id)));SheetControls.primary(_clean_button);actions.add_child(_clean_button)
  _stop_button=_action(_text.text("clean_stop"),"stop_clean",func():_session.hygiene.interrupt_clean());actions.add_child(_stop_button)
 if _care.get_child_count()==0:_care.add_child(SheetControls.label(ItemText.t("care_empty")))
func _render_jobs() -> void:
 for job in _session.workflow.jobs_at(_instance_id):
  var step: Dictionary=job.definition.steps[int(job.step_index)]
  var card := SheetControls.card(_active)
  card.get_parent().theme_type_variation="StationTray"
  var split := HBoxContainer.new()
  split.add_theme_constant_override("separation",8)
  card.add_child(split)
  var summary := VBoxContainer.new();summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL;summary.add_theme_constant_override("separation",4);split.add_child(summary)
  var commands := VBoxContainer.new();commands.size_flags_horizontal=Control.SIZE_EXPAND_FILL;commands.add_theme_constant_override("separation",4);split.add_child(commands)
  var heading := SheetControls.label(ItemText.recipe(str(job.recipe_id),str(job.definition.label)));SheetControls.muted(heading);summary.add_child(heading)
  var stage := SheetControls.label("%s / %s  ·  %s" % [int(job.step_index)+1,job.definition.steps.size(),ItemText.step(str(job.recipe_id),step)])
  stage.add_theme_color_override("font_color",Color("#24616b"));summary.add_child(stage)
  var meter := ProgressBar.new();meter.theme_type_variation="CookingProgress";meter.show_percentage=false;meter.custom_minimum_size.y=12;meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;summary.add_child(meter)
  var progress := SheetControls.label();summary.add_child(progress)
  _progress.append({"job_id":str(job.id),"step_id":str(step.id),"label":progress,"meter":meter})
  _step_track(summary,job)
  if step.kind=="cold_wait":summary.add_child(SheetControls.label(ItemText.t("cold_wait")))
  var id := StringName(str(job.id));var action := StringName(str(step.action))
  if step.kind=="batch_hold" or not job.definition.has("vessel_definition") and int(job.step_index)==job.definition.steps.size()-1:_serving_controls(commands,job)
  if step.kind!="passive_heat":
   var advance := _action(ItemText.step(str(job.recipe_id),step),str(id)+":advance",func():_apply(_session.workflow.act(id,action,_serving_options.get(str(id),{}))))
   SheetControls.primary(advance);commands.add_child(advance)
  if step.kind=="soak":summary.add_child(SheetControls.label(ItemText.t("soak_hint")))
  if RecipeProcesses.supports(job.definition):
   summary.add_child(SheetControls.label(ItemText.t("method",{"method":UiText.localized("cooking.method."+str(job.definition.method),{},str(job.definition.method))})))
   if step.kind in ["passive_heat","batch_hold"]:
    var heat_row := VBoxContainer.new();heat_row.add_theme_constant_override("separation",4);commands.add_child(heat_row)
    for heat in RecipeProcesses.HEATS:
     var heat_id: String=heat
     var heat_button := _action(UiText.localized("cooking.heat."+heat_id,{},heat_id),str(id)+":heat:"+heat_id,func():_apply(_session.workflow.act(id,StringName("heat:"+heat_id))))
     heat_button.disabled=job.heat==heat_id;heat_row.add_child(heat_button)
  if step.kind=="batch_heat":commands.add_child(_action(_text.text("recipe_stop_heat"),str(id)+":stop_heat",func():_apply(_session.workflow.act(id,&"stop_heat"))))
  var cancel_hint := SheetControls.label(ItemText.t("cancel_hint"));SheetControls.muted(cancel_hint);summary.add_child(cancel_hint)
  var cancel := _action(_text.text("recipe_cancel"),str(id)+":cancel",func():_apply(_session.workflow.act(id,&"cancel")))
  cancel.theme_type_variation="DangerButton";commands.add_child(cancel)
 if _progress.is_empty():_active.add_child(SheetControls.label(ItemText.t("active_empty")))
func _step_track(parent: VBoxContainer,job: Dictionary) -> void:
 # Steps come directly from the current job definition; no parallel progress state.
 var track := HFlowContainer.new()
 track.name="RecipeStepTrack"
 track.add_theme_constant_override("h_separation",4)
 track.add_theme_constant_override("v_separation",4)
 parent.add_child(track)
 var current := int(job.step_index)
 for index in range(job.definition.steps.size()):
  var step: Dictionary=job.definition.steps[index]
  var marker := UiText.label(str(index+1))
  marker.theme_type_variation="RecipeStepDone" if index<current else "RecipeStepNow" if index==current else "RecipeStepLater"
  marker.custom_minimum_size=Vector2(42,28)
  marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  marker.set_meta("centered",true)
  marker.tooltip_text=ItemText.step(str(job.recipe_id),step)
  marker.mouse_filter=Control.MOUSE_FILTER_STOP
  track.add_child(marker)

func _render_recipes() -> void:
 var available := _session.workflow.available_recipes(_session.location_id,_instance_id,_selected_ingredients)
 _recipes.set_meta("has_recipes",not available.is_empty())
 for recipe in available:
  var definition: Dictionary=recipe.definition
  var card := SheetControls.card(_recipes)
  card.get_parent().theme_type_variation="RecipePaper"
  var heading := SheetControls.label(ItemText.recipe(str(recipe.id),str(definition.label)));SheetControls.title(heading);card.add_child(heading)
  _ingredient_strip(card,definition)
  var equipment := SheetControls.label(ItemText.equipment(definition));SheetControls.muted(equipment);card.add_child(equipment)
  if not recipe.available:
   var reason := ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,recipe.missing,recipe.details)
   card.add_child(SheetControls.label(_text.text("recipe_missing",{"reason":ItemText.missing(_session,_text,reason)})))
  var id := StringName(str(recipe.id))
  for input in definition.inputs:
   var input_id: String=str(input.definition_id)
   var options := _session.workflow.grade_options(StringName(input_id),_session.location_id)
   var selected := str(_selected_ingredients.get(str(id),{}).get(input_id,""))
   if options.size()<2 and selected.is_empty():continue
   var row := SheetControls.columns(card,620)
   row.add_child(SheetControls.label(ItemText.definition(_session,input_id)))
   var picker := OptionButton.new();picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;picker.fit_to_longest_item=false;picker.clip_text=true;picker.set_meta("recipe_focus",str(id)+":grade:"+input_id);row.add_child(picker)
   picker.add_item(ItemText.t("oldest_grade"));picker.set_item_metadata(0,"")
   for grade in options:
    picker.add_item(UiText.localized("ingredient.grade."+grade,{},grade));picker.set_item_metadata(picker.item_count-1,grade)
   if not selected.is_empty() and not selected in options:
    picker.add_item(UiText.localized("ingredient.grade."+selected,{},selected)+" · "+ItemText.t("grade_empty"));picker.set_item_metadata(picker.item_count-1,selected);picker.set_item_disabled(picker.item_count-1,true)
   for index in range(picker.item_count):
    if picker.get_item_metadata(index)==selected:picker.select(index)
   picker.item_selected.connect(func(index):
    var picks: Dictionary=_selected_ingredients.get(str(id),{}).duplicate(true)
    var grade := str(picker.get_item_metadata(index))
    if grade.is_empty():picks.erase(input_id)
    else:picks[input_id]=grade
    _selected_ingredients[str(id)]=picks;_dirty=true)
  var actions := SheetControls.columns(card,720)
  var start := _action(_text.text("recipe_start"),str(id)+":start",func():_apply(_session.workflow.start(id,_session.location_id,PackedStringArray([str(_instance_id)]),false,_selected_ingredients.get(str(id),{}))))
  SheetControls.primary(start)
  start.disabled=not recipe.available;actions.add_child(start)
  var personal := _action(_text.text("self_cooking"),str(id)+":personal",func():_apply(_session.workflow.start(id,_session.location_id,PackedStringArray([str(_instance_id)]),true,_selected_ingredients.get(str(id),{}))))
  personal.disabled=not recipe.available;actions.add_child(personal)
 if available.is_empty():_recipes.add_child(SheetControls.label(ItemText.t("recipes_empty")))
func _ingredient_strip(parent: VBoxContainer,definition: Dictionary) -> void:
 var strip := HFlowContainer.new()
 strip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 strip.add_theme_constant_override("h_separation",8)
 strip.add_theme_constant_override("v_separation",6)
 parent.add_child(strip)
 for input in definition.inputs:
  var input_id := str(input.definition_id)
  var slot := PanelContainer.new()
  slot.theme_type_variation="ItemSlot"
  slot.custom_minimum_size.x=126
  strip.add_child(slot)
  var column := VBoxContainer.new()
  column.add_theme_constant_override("separation",2)
  slot.add_child(column)
  var glyph := ItemGlyph.new()
  glyph.configure(_session.items.definition(StringName(input_id)),input_id)
  glyph.custom_minimum_size=Vector2(56,56)
  glyph.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  column.add_child(glyph)
  var quantity := SheetControls.label(ItemText.t("quantity",{"name":ItemText.definition(_session,input_id),"quantity":int(input.quantity)}))
  quantity.custom_minimum_size.x=100
  quantity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  quantity.set_meta("centered",true)
  column.add_child(quantity)

func _apply(result: ActionResult) -> void:
 _last_result=result;_dirty=true
 if result.ok and result.details.has("job_id"):_tabs.current_tab=1
func _process(delta: float) -> void:
 if not visible:return
 if _dirty:_refresh()
 _elapsed+=delta
 if _elapsed>=0.2:_elapsed=0;_update_progress()
func _update_progress() -> void:
 for entry in _progress:
  var value := _session.workflow.progress_view(StringName(entry.job_id))
  if value.is_empty() or value.step_id!=entry.step_id:_dirty=true;continue
  entry.meter.visible=float(value.duration)>0
  entry.meter.max_value=maxf(0.001,float(value.duration))
  entry.meter.value=minf(float(value.elapsed),float(value.duration))
  var line := _text.text("recipe_progress",{"elapsed":"%.1f" % float(value.elapsed),"duration":value.duration})
  if value.kind in ["batch_heat","batch_hold"]:
   line+=" · "+_text.text("recipe_portions",{"count":value.portions})
   if not value.heat_on:line+="\n"+ItemText.t("heat_off")
   if value.slicing:line+="\n"+_text.outcome(ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"slice_in_progress"))
  if not str(value.get("freshness_stage","")).is_empty():line+=" · "+UiText.localized("freshness."+str(value.freshness_stage),{},str(value.freshness_stage))
  entry.label.text=line
 if is_instance_valid(_cleanliness):
  var state := _session.hygiene.state(_instance_id)
  _cleanliness.text=ItemText.hygiene(_hygiene_data,state)
  var cleaning := _session.hygiene.is_cleaning(_instance_id)
  _clean_button.disabled=cleaning or float(state.get("cleanliness",100))>=100
  _stop_button.visible=cleaning
  _clean_progress.visible=cleaning
  if cleaning:
   var progress: Dictionary=state.get("cleaning",{})
   _clean_progress.text=ItemText.t("cleaning",{"minutes":"%.1f" % maxf(0,float(progress.get("required_minutes",0))-float(progress.get("completed_minutes",0)))})

func _serving_controls(card: VBoxContainer, job: Dictionary) -> void:
 var food := str(job.definition.output.food_id)
 var options: Dictionary=_serving_options.get(str(job.id),{"variant_id":_session.menu.default_variant(food),"additions":[]})
 var variants := _session.menu.variants(food)
 var picker := OptionButton.new();picker.fit_to_longest_item=false;picker.clip_text=true;picker.set_meta("recipe_focus",str(job.id)+":serving");card.add_child(picker)
 for id in variants:
  picker.add_item(UiText.localized("serving."+id.get_slice("/",1),{},id.get_slice("/",1))+" · "+UiText.localized("serving."+id.get_slice("/",2),{},id.get_slice("/",2)))
  if id==str(options.variant_id):picker.select(picker.item_count-1)
 picker.item_selected.connect(func(index):options.variant_id=variants[index];_serving_options[str(job.id)]=options.duplicate(true))
 for addition in _session.menu._data.foods[food].additions:
  var id: String=str(addition)
  var toggle := CheckBox.new();toggle.text=UiText.localized("addition."+id,{},id);toggle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toggle.set_meta("recipe_focus",str(job.id)+":addition:"+id);toggle.button_pressed=id in options.additions;card.add_child(toggle)
  toggle.toggled.connect(func(enabled):
   if enabled and not id in options.additions:options.additions.append(id)
   elif not enabled:options.additions.erase(id)
   _serving_options[str(job.id)]=options.duplicate(true))
func _action(value: String, key: String, action: Callable) -> Button:
 var button := SheetControls.button(value,action);button.set_meta("recipe_focus",key);button.custom_minimum_size.x=0;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return button
func _focused_key() -> String:
 var focused := get_viewport().gui_get_focus_owner()
 return str(focused.get_meta("recipe_focus","")) if focused!=null and is_ancestor_of(focused) else ""
func _restore_focus(key: String) -> void:
 if key.is_empty():return
 for control in _tabs.find_children("*","BaseButton",true,false):
  if str(control.get_meta("recipe_focus",""))==key and not control.disabled:
   control.call_deferred("grab_focus");return
