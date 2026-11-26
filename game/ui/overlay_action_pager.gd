class_name OverlayActionPager
extends VBoxContainer
## Presentation only. The original controls keep their native callbacks,
## order, values and labels. Paging never executes a gameplay command.
signal page_changed(index: int)
var _controls: Array[Control]=[]
var _row: HBoxContainer
var _previous: Button
var _next: Button
var _counter: Label
var _index: int=0
var _paged: bool=false
func configure(actions: Array[Control]) -> void:
 _controls=actions
 add_theme_constant_override("separation",4)
 _row=HBoxContainer.new()
 _row.add_theme_constant_override("separation",4)
 add_child(_row)
 _previous=UiText.button("‹",func():select(_index-1))
 _next=UiText.button("›",func():select(_index+1))
 for button in [_previous,_next]:
  button.custom_minimum_size=Vector2(44,44)
  button.theme_type_variation="QuietButton"
 _previous.tooltip_text=UiText.localized("cozy.overlay_previous")
 _next.tooltip_text=UiText.localized("cozy.overlay_next")
 _counter=UiText.label()
 _counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _counter.set_meta("centered",true)
 _counter.layout_direction=Control.LAYOUT_DIRECTION_LTR
 _counter.text_direction=Control.TEXT_DIRECTION_LTR
 _counter.custom_minimum_size.x=36
 _counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _row.add_child(_previous);_row.add_child(_counter);_row.add_child(_next)
 for control in _controls:
  control.reparent(self,false)
  control.custom_minimum_size.y=maxf(44,control.custom_minimum_size.y)
  control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 move_child(_row,get_child_count()-1)
 set_paged(false)

# An optional persistent header host keeps navigation out of the reading area.
# Return the row before clearing the owning pager or rebuilding its controls.
func set_navigation_host(host: Control) -> void:
 var target: Control=host if is_instance_valid(host) else self
 if _row.get_parent()!=target:_row.reparent(target,false)
 if target==self:move_child(_row,get_child_count()-1)
 _row.size_flags_horizontal=Control.SIZE_SHRINK_CENTER if target!=self else Control.SIZE_EXPAND_FILL
 _row.visible=_paged and _controls.size()>1

func set_paged(value: bool) -> void:
 _paged=value
 _row.visible=value and _controls.size()>1
 _apply()
func select(index: int) -> void:
 _index=clampi(index,0,maxi(0,_controls.size()-1))
 _apply()
 page_changed.emit(_index)
func _apply() -> void:
 if not is_instance_valid(_row):return
 for i in range(_controls.size()):
  _controls[i].visible=not _paged or i==_index
 _counter.text="%s / %s" % [_index+1,_controls.size()]
 _previous.disabled=_index<=0
 _next.disabled=_index>=_controls.size()-1
func selected_control() -> Control:
 return _controls[_index] if not _controls.is_empty() else null
