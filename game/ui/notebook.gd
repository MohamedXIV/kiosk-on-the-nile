class_name Notebook
extends PanelContainer
signal closed
var _session: GameSession
var _text: UiText
var _tabs := TabContainer.new()
var _notes := VBoxContainer.new()
var _people := VBoxContainer.new()
var _history := NotebookHistory.new()
var _accounts := NotebookAccounts.new()
var _subtitle := Label.new()
var _journal_revision: int=-1
var _notes_key: String=""
var _people_key: String=""
const TAB_KEYS := ["notebook_notes","notebook_people","journal_title","accounts_title"]
func configure(text: UiText) -> void:
 _text=text
 SheetControls.shell(self,1120)
 theme=text.make_theme()
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",10)
 add_child(box)
 var heading := text.key_label("notebook")
 SheetControls.header(box,heading,text,func():hide();closed.emit())
 _subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;SheetControls.muted(_subtitle);box.add_child(_subtitle)
 _tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _tabs.get_tab_bar().scrolling_enabled=true
 _tabs.get_tab_bar().clip_tabs=true
 box.add_child(_tabs)
 _tabs.add_child(_scroll(_notes))
 _tabs.add_child(_scroll(_people))
 var size: int=int(text.data.get("notebook_layout",{}).get("history_page_size",40))
 _history.configure(size);_tabs.add_child(_history)
 _accounts.configure(size);_tabs.add_child(_accounts)
 _tabs.tab_changed.connect(func(_index):refresh())
 LocaleService.current.changed.connect(_refresh_language)
 _refresh_language()
 hide()
func _scroll(box: VBoxContainer) -> ScrollContainer:
 var scroll := ScrollContainer.new()
 scroll.follow_focus=true
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 box.add_theme_constant_override("separation",12)
 scroll.add_child(box)
 return scroll
func bind_session(session: GameSession) -> void:
 _session=session
 _accounts.bind_session(session)
func open() -> void:
 refresh()
 show()
func refresh() -> void:
 if _session==null:return
 if _journal_revision!=_session.journal.revision:
  _history.set_entries(_session.journal.entries())
  _journal_revision=_session.journal.revision
 if _tabs.current_tab==0:_render_notes()
 elif _tabs.current_tab==1:_render_people()
 elif _tabs.current_tab==3:_accounts.refresh()
func _refresh_language() -> void:
 _subtitle.text=NotebookView.t("subtitle")
 for i in range(TAB_KEYS.size()):_tabs.set_tab_title(i,_text.text(TAB_KEYS[i]))
 _history.refresh_language()
 _accounts.refresh_language()
 _notes_key="";_people_key=""
 if visible:refresh()
func _clear(box: VBoxContainer) -> void:
 for child in box.get_children():child.free()
func _label(value: String) -> Label:
 var label := UiText.label(value)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return label
func _card(parent: VBoxContainer) -> VBoxContainer:
 return SheetControls.card(parent)
func _render_notes() -> void:
 var notes := NotebookView.notes(_session)
 var reputation := NotebookView.reputation(_session)
 var key := str(LocaleService.current.revision)+JSON.stringify(notes)+reputation
 if key==_notes_key:return
 _notes_key=key;_clear(_notes)
 var reputation_card := _card(_notes)
 var reputation_label := _label(reputation);SheetControls.muted(reputation_label);reputation_card.add_child(reputation_label)
 if notes.is_empty():_notes.add_child(_label(NotebookView.t("notes_empty")))
 for note in notes:
  var box := _card(_notes)
  box.add_child(_label(str(note.text)))
  var chapter := str(note.chapter)
  if chapter!="" and _history.has_chapter(chapter):
   var button := UiText.button(NotebookView.t("source"),func():_history.show_chapter(chapter);_tabs.current_tab=2)
   button.focus_mode=Control.FOCUS_ALL;button.theme_type_variation="QuietButton";button.custom_minimum_size.y=44;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(button)
func _render_people() -> void:
 var people := NotebookView.people(_session)
 var key := str(LocaleService.current.revision)+JSON.stringify(people)
 if key==_people_key:return
 _people_key=key;_clear(_people)
 var hint := _label(NotebookView.t("people_hint"));SheetControls.muted(hint);_people.add_child(hint)
 if people.is_empty():_people.add_child(_label(NotebookView.t("people_empty")))
 for person in people:
  var box := _card(_people)
  var name_label := _label(str(person.name));SheetControls.title(name_label);box.add_child(name_label)
  box.add_child(_label(str(person.stage)))
  var bar := ProgressBar.new();bar.value=float(person.score);bar.show_percentage=false;bar.custom_minimum_size.y=12;box.add_child(bar)
  if str(person.connection)!="":
   var connection := _label(str(person.connection));SheetControls.muted(connection);box.add_child(connection)
