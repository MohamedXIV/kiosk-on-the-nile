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
 theme_type_variation="NotebookCover"
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",10)
 add_child(box)
 var heading := text.key_label("notebook")
 SheetControls.header(box,heading,text,func():hide();closed.emit(),"notebook","SectionNile")
 heading.theme_type_variation="NotebookSection"
 _subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;SheetControls.muted(_subtitle);box.add_child(_subtitle)
 _tabs.theme_type_variation="NotebookBook"
 _tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _tabs.get_tab_bar().theme_type_variation="NotebookTabs"
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
func _page(parent: Container,kind: String="NotebookPage") -> VBoxContainer:
 var panel := PanelContainer.new()
 panel.theme_type_variation=kind
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(panel)
 var page := VBoxContainer.new()
 page.add_theme_constant_override("separation",8)
 panel.add_child(page)
 return page
func _render_notes() -> void:
 var notes := NotebookView.notes(_session)
 var reputation := NotebookView.reputation(_session)
 var key := str(LocaleService.current.revision)+JSON.stringify(notes)+reputation
 if key==_notes_key:return
 _notes_key=key;_clear(_notes)
 var page := VBoxContainer.new()
 page.add_theme_constant_override("separation",14)
 _notes.add_child(page)
 var reputation_row := SheetControls.banner(page,"notebook","NotebookBookmark")
 var reputation_label := _label(reputation)
 reputation_label.theme_type_variation="NotebookSection"
 reputation_row.add_child(reputation_label)
 page.add_child(HSeparator.new())
 if notes.is_empty():page.add_child(_label(NotebookView.t("notes_empty")))
 for note in notes:
  var box := VBoxContainer.new()
  box.add_theme_constant_override("separation",5)
  page.add_child(box)
  var passage := _label(str(note.text))
  passage.theme_type_variation="NotebookPassage"
  passage.add_theme_font_size_override("font_size",17)
  passage.add_theme_constant_override("line_spacing",5)
  box.add_child(passage)
  var chapter := str(note.chapter)
  if chapter!="" and _history.has_chapter(chapter):
   var button := UiText.button(NotebookView.t("source"),func():_history.show_chapter(chapter);_tabs.current_tab=2)
   button.focus_mode=Control.FOCUS_ALL;button.theme_type_variation="QuietButton";button.custom_minimum_size.y=44;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(button)
  page.add_child(HSeparator.new())
func _render_people() -> void:
 var people := NotebookView.people(_session)
 var key := str(LocaleService.current.revision)+JSON.stringify(people)
 if key==_people_key:return
 _people_key=key;_clear(_people)
 var hint := _label(NotebookView.t("people_hint"));SheetControls.muted(hint);_people.add_child(hint)
 if people.is_empty():_people.add_child(_label(NotebookView.t("people_empty")))
 var grid := GridContainer.new()
 grid.columns=2 if size.x>=780 else 1
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",10)
 _people.add_child(grid)
 grid.resized.connect(func():grid.columns=2 if _people.size.x>=740 else 1)
 for person in people:
  var box := _page(grid,"PersonPage")
  # An index card, not a fabricated portrait. Initial derives from the localized name.
  var contact_row := HBoxContainer.new()
  contact_row.add_theme_constant_override("separation",10)
  box.add_child(contact_row)
  var monogram := UiText.label(str(person.name).substr(0,1))
  monogram.theme_type_variation="ContactMonogram"
  monogram.custom_minimum_size=Vector2(48,48)
  monogram.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  monogram.set_meta("centered",true)
  contact_row.add_child(monogram)
  var identity := VBoxContainer.new()
  identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  identity.add_theme_constant_override("separation",2)
  contact_row.add_child(identity)
  var name_label := _label(str(person.name));name_label.theme_type_variation="NotebookSection";identity.add_child(name_label)
  identity.add_child(_label(str(person.stage)))
  var bar := ProgressBar.new();bar.theme_type_variation="ContactProgress";bar.value=float(person.score);bar.show_percentage=false;bar.custom_minimum_size.y=8;box.add_child(bar)
  if str(person.connection)!="":
   var connection := _label(str(person.connection));SheetControls.muted(connection);box.add_child(connection)
