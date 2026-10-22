class_name Notebook
extends PanelContainer
signal closed
var _notes: RichTextLabel
func configure(text: UiText) -> void:
 anchor_left = 0.2
 anchor_right = 0.8
 anchor_top = 0.16
 anchor_bottom = 0.82
 theme = text.make_theme()
 var box := VBoxContainer.new()
 add_child(box)
 box.add_child(UiText.label(text.text("notebook")))
 _notes = RichTextLabel.new()
 _notes.text_direction = Control.TEXT_DIRECTION_RTL
 _notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
 _notes.custom_minimum_size = Vector2(350,200)
 box.add_child(_notes)
 box.add_child(UiText.button(text.text("close"),func():hide();closed.emit()))
 hide()
func present(notes: PackedStringArray) -> void:
 _notes.text = "\n\n".join(notes)
 show()
