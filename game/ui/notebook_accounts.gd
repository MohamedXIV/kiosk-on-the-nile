class_name NotebookAccounts
extends VBoxContainer
## Read-only summary and paged original receipts; signed text stays untouched.
var _session: GameSession
var _mode := OptionButton.new()
var _hint := Label.new()
var _body := RichTextLabel.new()
var _paging := HBoxContainer.new()
var _count := Label.new()
var _previous: Button
var _next: Button
var _page: int=0
var _page_size: int=40
var _receipt_key: String=""
var _display_text: String=""
var _receipts: Array[Dictionary]=[]
func configure(page_size: int) -> void:
 _page_size=page_size
 _mode.add_item("");_mode.add_item("")
 _mode.item_selected.connect(func(_index):_page=0;refresh(true))
 add_child(_mode)
 _hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(_hint)
 _body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _body.selection_enabled=true
 _body.text_direction=Control.TEXT_DIRECTION_AUTO
 add_child(_body)
 add_child(_paging)
 _previous=UiText.button("",func():_page-=1;refresh(true));_previous.focus_mode=Control.FOCUS_ALL;_paging.add_child(_previous)
 _count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_paging.add_child(_count)
 _next=UiText.button("",func():_page+=1;refresh(true));_next.focus_mode=Control.FOCUS_ALL;_paging.add_child(_next)
 refresh_language()
func bind_session(session: GameSession) -> void:_session=session
func refresh_language() -> void:
 _mode.set_item_text(0,NotebookView.t("accounts_summary"));_mode.set_item_text(1,NotebookView.t("accounts_receipts"))
 _previous.text=NotebookView.t("previous");_next.text=NotebookView.t("next")
 _receipt_key="";_display_text=""
 if _session:refresh()
func refresh(reset_scroll: bool=false) -> void:
 if _session==null:return
 _body.text_direction=Control.TEXT_DIRECTION_AUTO
 _hint.text=NotebookView.t("accounts_hint" if _mode.selected==0 else "signed_hint")
 var scroll := _body.get_v_scroll_bar().value
 _paging.visible=_mode.selected==1
 if _mode.selected==0:
  var display := NotebookView.accounts(_session)
  _show_text(display)
 else:
  var key := str([_session.accounts.state.receipts.size(),_session.commitments.state.receipts.size(),_session.accounts.state.supplier.receipts.size(),LocaleService.current.revision])
  if key!=_receipt_key:_receipts=NotebookView.receipts(_session);_receipt_key=key
  _page=clampi(_page,0,maxi(0,ceili(float(_receipts.size())/_page_size)-1))
  var start := _page*_page_size;var end := mini(start+_page_size,_receipts.size())
  var lines := PackedStringArray()
  for receipt in _receipts.slice(start,end):lines.append(str(receipt.text))
  _show_text("\n\n".join(lines) if not lines.is_empty() else NotebookView.t("receipts_empty"))
  _count.text=NotebookView.t("page",{"start":start+1 if end>0 else 0,"end":end,"total":_receipts.size()})
  _previous.disabled=_page==0;_next.disabled=end>=_receipts.size()
 _body.get_v_scroll_bar().set_deferred("value",0.0 if reset_scroll else scroll)

func _show_text(value: String) -> void:
 if value==_display_text:return
 _display_text=value
 NotebookView.readable_text(_body,value)
