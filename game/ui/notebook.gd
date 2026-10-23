class_name Notebook
extends PanelContainer
signal closed
var _notes: RichTextLabel
var _people := VBoxContainer.new()
func configure(text: UiText) -> void:
 anchor_left=0.15;anchor_right=0.85;anchor_top=0.16;anchor_bottom=0.82
 theme=text.make_theme()
 var box := VBoxContainer.new()
 add_child(box)
 box.add_child(UiText.label(text.text("notebook")))
 var tabs := TabContainer.new()
 tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(tabs)
 _notes=RichTextLabel.new()
 _notes.name=text.text("notebook_notes")
 _notes.text_direction=Control.TEXT_DIRECTION_RTL
 _notes.custom_minimum_size=Vector2(350,180)
 tabs.add_child(_notes)
 var scroll := ScrollContainer.new()
 scroll.name=text.text("notebook_people")
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 tabs.add_child(scroll)
 _people.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(_people)
 box.add_child(UiText.button(text.text("close"),func():hide();closed.emit()))
 hide()
func present(notes: PackedStringArray, people: Array[Dictionary] = []) -> void:
 _notes.text="\n\n".join(notes)
 for child in _people.get_children():child.free()
 for person in people:
  _people.add_child(UiText.label(str(person.name)+" — "+str(person.stage)))
  var bar := ProgressBar.new()
  bar.value=float(person.score)
  bar.show_percentage=false
  bar.custom_minimum_size.y=10
  bar.tooltip_text=str(person.stage)
  _people.add_child(bar)
  if not str(person.connection).is_empty():_people.add_child(UiText.label(person.connection))
 show()
