class_name NotebookHistory
extends VBoxContainer
## Filtered, paged snapshots of actual heard text. Never calls narrative commands.
var _actor := OptionButton.new()
var _day := OptionButton.new()
var _chapter := OptionButton.new()
var _channel := OptionButton.new()
var _order := OptionButton.new()
var _search := LineEdit.new()
var _body := RichTextLabel.new()
var _hint := Label.new()
var _count := Label.new()
var _reset: Button
var _previous: Button
var _next: Button
var _entries: Array[Dictionary]=[]
var _filtered: Array[Dictionary]=[]
var _page: int=0
var _page_size: int=40
var _changing: bool=false
func configure(page_size: int) -> void:
 _page_size=page_size
 _hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(_hint)
 _search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _search.clear_button_enabled=true
 _search.text_changed.connect(func(_value):_apply_filters())
 add_child(_search)
 var filters := HFlowContainer.new()
 filters.add_theme_constant_override("h_separation",8)
 filters.add_theme_constant_override("v_separation",6)
 add_child(filters)
 for field in [_actor,_day,_chapter,_channel,_order]:
  field.custom_minimum_size.x=150
  field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  field.fit_to_longest_item=false
  filters.add_child(field)
  field.item_selected.connect(func(_index):if not _changing:_apply_filters())
 _reset=_button("reset",clear_filters);filters.add_child(_reset)
 _body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _body.text_direction=Control.TEXT_DIRECTION_AUTO
 _body.selection_enabled=true
 add_child(_body)
 var paging := HBoxContainer.new()
 paging.add_theme_constant_override("separation",10)
 add_child(paging)
 _previous=_button("previous",func():_page-=1;_render(true));paging.add_child(_previous)
 _count.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 paging.add_child(_count)
 _next=_button("next",func():_page+=1;_render(true));paging.add_child(_next)
 _rebuild_options()
 refresh_language()
func _button(key: String, action: Callable) -> Button:
 var button := UiText.button(NotebookView.t(key),action)
 button.focus_mode=Control.FOCUS_ALL
 button.set_meta("notebook_key",key)
 return button
func _metadata(field: OptionButton, fallback: Variant) -> Variant:
 return field.get_selected_metadata() if field.selected>=0 else fallback
func _fill(field: OptionButton, values: Array, selected: Variant) -> void:
 field.clear()
 for value in values:
  field.add_item(str(value.label))
  field.set_item_metadata(field.item_count-1,value.id)
  if value.id==selected:field.select(field.item_count-1)
func _rebuild_options() -> void:
 _changing=true
 var actor: Variant=_metadata(_actor,"")
 var day: Variant=_metadata(_day,0)
 var chapter: Variant=_metadata(_chapter,"")
 var channel: Variant=_metadata(_channel,"")
 var order: Variant=_metadata(_order,"newest")
 var actors: Array=[{"id":"","label":NotebookView.t("people_all")}]
 var days: Array=[{"id":0,"label":NotebookView.t("days_all")}]
 var chapters: Array=[{"id":"","label":NotebookView.t("chapters_all")}]
 var known_actors: Dictionary={};var known_days: Dictionary={};var known_chapters: Dictionary={}
 for event in _entries:
  if not known_actors.has(event.actor):
   known_actors[event.actor]=true;actors.append({"id":event.actor,"label":event.name})
  known_days[floori(float(event.at)/1440)+1]=true
  if not known_chapters.has(event.chapter):
   known_chapters[event.chapter]=true
   chapters.append({"id":event.chapter,"label":NotebookView.t("chapter",{"number":known_chapters.size(),"name":str(event.name)})})
 var day_ids: Array=known_days.keys();day_ids.sort();day_ids.reverse()
 for id in day_ids:days.append({"id":id,"label":NotebookView.t("day",{"day":id})})
 _fill(_actor,actors,actor);_fill(_day,days,day);_fill(_chapter,chapters,chapter)
 var channels: Array=[{"id":"","label":NotebookView.t("channels_all")}]
 for id in ["speech","choice","thought","system"]:channels.append({"id":id,"label":NotebookView.t("channel."+id)})
 _fill(_channel,channels,channel)
 _fill(_order,[{"id":"newest","label":NotebookView.t("newest")},{"id":"oldest","label":NotebookView.t("oldest")}],order)
 _changing=false
func set_entries(entries: Array[Dictionary]) -> void:
 _entries=entries
 _rebuild_options()
 _apply_filters(false)
func refresh_language() -> void:
 _hint.text=NotebookView.t("history_hint")
 _search.placeholder_text=NotebookView.t("search")
 _search.tooltip_text=NotebookView.t("search_label")
 for pair in [[_actor,"actor_filter"],[_day,"day_filter"],[_chapter,"chapter_filter"],[_channel,"channel_filter"]]:pair[0].tooltip_text=NotebookView.t(str(pair[1]))
 for button in [_reset,_previous,_next]:button.text=NotebookView.t(str(button.get_meta("notebook_key")))
 _rebuild_options()
 _apply_filters(false)
func clear_filters() -> void:
 _changing=true
 for field in [_actor,_day,_chapter,_channel,_order]:field.select(0)
 _search.text=""
 _changing=false
 _apply_filters()
func show_chapter(id: String) -> void:
 clear_filters()
 for i in range(_chapter.item_count):
  if str(_chapter.get_item_metadata(i))==id:
   _chapter.select(i);_apply_filters();return
func has_chapter(id: String) -> bool:
 for event in _entries:
  if event.chapter==id:return true
 return false
func _apply_filters(reset_page: bool=true) -> void:
 if _changing:return
 if reset_page:_page=0
 var actor := str(_metadata(_actor,""))
 var day := int(_metadata(_day,0))
 var chapter := str(_metadata(_chapter,""))
 var channel := str(_metadata(_channel,""))
 var query := _search.text.strip_edges().to_lower()
 var related: Dictionary={}
 if actor!="":
  for event in _entries:
   if event.actor==actor:related[event.chapter]=true
 _filtered.clear()
 for event in _entries:
  if actor!="" and not related.has(event.chapter):continue
  if day>0 and floori(float(event.at)/1440)+1!=day:continue
  if chapter!="" and event.chapter!=chapter:continue
  if channel!="" and event.channel!=channel:continue
  if query!="" and not query in (str(event.name)+"\n"+str(event.text)).to_lower():continue
  _filtered.append(event)
 if _metadata(_order,"newest")=="newest":_filtered.reverse()
 _render(reset_page)
func _render(reset_scroll: bool) -> void:
 _body.text_direction=Control.TEXT_DIRECTION_AUTO
 var scroll := _body.get_v_scroll_bar().value
 _page=clampi(_page,0,maxi(0,ceili(float(_filtered.size())/_page_size)-1))
 var start := _page*_page_size
 var end := mini(start+_page_size,_filtered.size())
 var lines := PackedStringArray()
 for event in _filtered.slice(start,end):
  var minute := int(fposmod(float(event.at),1440))
  lines.append(NotebookView.t("entry",{"day":floori(float(event.at)/1440)+1,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60),"name":str(event.name),"body":str(event.text)}))
 _body.text="\n\n".join(lines) if not lines.is_empty() else NotebookView.t("history_empty" if _entries.is_empty() else "history_no_match")
 _count.text=NotebookView.t("page",{"start":start+1 if end>0 else 0,"end":end,"total":_filtered.size()})
 _previous.disabled=_page==0;_next.disabled=end>=_filtered.size()
 _body.get_v_scroll_bar().set_deferred("value",0.0 if reset_scroll else scroll)
