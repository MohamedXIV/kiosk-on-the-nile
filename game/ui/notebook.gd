class_name Notebook
extends PanelContainer
signal closed
var _notes: RichTextLabel
var _people := VBoxContainer.new()
var _tabs := TabContainer.new()
var _actor := OptionButton.new()
var _day := OptionButton.new()
var _chapter := OptionButton.new()
var _history := RichTextLabel.new()
var _entries: Array[Dictionary]=[]
var _ui: Dictionary={}
var _links := VBoxContainer.new()
func configure(text: UiText) -> void:
 _ui=text.data
 anchor_left=0.12;anchor_right=0.88;anchor_top=0.14;anchor_bottom=0.86
 theme=text.make_theme()
 var box := VBoxContainer.new()
 add_child(box)
 box.add_child(UiText.label(text.text("notebook")))
 _tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(_tabs)
 var notes_box := VBoxContainer.new()
 notes_box.name=text.text("notebook_notes")
 _tabs.add_child(notes_box)
 _notes=RichTextLabel.new()
 _notes.text_direction=Control.TEXT_DIRECTION_RTL
 _notes.custom_minimum_size=Vector2(300,120)
 _notes.size_flags_vertical=Control.SIZE_EXPAND_FILL
 notes_box.add_child(_notes)
 notes_box.add_child(_links)
 var people_scroll := ScrollContainer.new()
 people_scroll.name=text.text("notebook_people")
 people_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _tabs.add_child(people_scroll)
 _people.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 people_scroll.add_child(_people)
 var journal := VBoxContainer.new()
 journal.name=text.text("journal_title")
 _tabs.add_child(journal)
 var filters := HFlowContainer.new()
 journal.add_child(filters)
 for control in [_actor,_day,_chapter]:
  control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  filters.add_child(control)
  control.item_selected.connect(func(_index):_render_history())
 _history.text_direction=Control.TEXT_DIRECTION_RTL
 _history.size_flags_vertical=Control.SIZE_EXPAND_FILL
 journal.add_child(_history)
 box.add_child(UiText.button(text.text("close"),func():hide();closed.emit()))
 hide()
func present(notes: PackedStringArray, people: Array[Dictionary] = [], entries: Array[Dictionary] = [], ui: Dictionary = {}, sources: Array[Dictionary] = []) -> void:
 if not ui.is_empty():_ui=ui
 _entries=entries.duplicate(true)
 _notes.text="\n\n".join(notes)
 for child in _people.get_children():child.free()
 for person in people:
  _people.add_child(UiText.label(str(person.name)+" — "+str(person.stage)))
  var bar := ProgressBar.new()
  bar.value=float(person.score);bar.show_percentage=false;bar.custom_minimum_size.y=10
  _people.add_child(bar)
  if not str(person.connection).is_empty():_people.add_child(UiText.label(person.connection))
 _actor.clear();_day.clear();_chapter.clear()
 _actor.add_item(str(_ui.journal_all));_actor.set_item_metadata(0,"")
 _day.add_item(str(_ui.journal_all_days));_day.set_item_metadata(0,0)
 _chapter.add_item(str(_ui.journal_all));_chapter.set_item_metadata(0,"")
 var actors: Dictionary={};var days: Dictionary={};var chapters: Dictionary={}
 for entry in _entries:
  if not actors.has(entry.actor):
   actors[entry.actor]=true
   _actor.add_item(str(entry.name));_actor.set_item_metadata(_actor.item_count-1,str(entry.actor))
  var day := floori(float(entry.at)/1440)+1
  if not days.has(day):
   days[day]=true
   _day.add_item("اليوم "+str(day));_day.set_item_metadata(_day.item_count-1,day)
  if not chapters.has(entry.chapter):
   chapters[entry.chapter]=true
   _chapter.add_item((str(_ui.thought_name) if entry.channel=="thought" else "قعدة")+" "+str(chapters.size()))
   _chapter.set_item_metadata(_chapter.item_count-1,str(entry.chapter))
 for child in _links.get_children():child.free()
 for source in sources:
  if not chapters.has(source.chapter):continue
  var button := UiText.button(str(source.label),_show_chapter.bind(str(source.chapter)))
  button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  _links.add_child(button)
 _render_history()
 show()
func _show_chapter(id: String) -> void:
 _actor.select(0);_day.select(0)
 for i in range(_chapter.item_count):
  if _chapter.get_item_metadata(i)==id:_chapter.select(i)
 _tabs.current_tab=2
 _render_history()
func _render_history() -> void:
 var actor := str(_actor.get_selected_metadata())
 var day := int(_day.get_selected_metadata())
 var chapter := str(_chapter.get_selected_metadata())
 var related: Dictionary={}
 if not actor.is_empty():
  for entry in _entries:
   if entry.actor==actor:related[entry.chapter]=true
 var lines := PackedStringArray()
 for entry in _entries:
  if not actor.is_empty() and not related.has(entry.chapter):continue
  if not chapter.is_empty() and entry.chapter!=chapter:continue
  var entry_day := floori(float(entry.at)/1440)+1
  if day>0 and entry_day!=day:continue
  var minute := int(fposmod(float(entry.at),1440))
  var name := str(_ui.thought_name) if entry.channel=="thought" else str(entry.name)
  lines.append("اليوم %d · %02d:%02d · %s\n%s" % [entry_day,minute/60,minute%60,name,entry.text])
 _history.text="\n\n".join(lines) if not lines.is_empty() else str(_ui.journal_empty)
