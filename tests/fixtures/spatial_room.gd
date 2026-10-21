extends Node2D
func _ready() -> void:
 var floor_view := Polygon2D.new()
 floor_view.polygon = PackedVector2Array([Vector2(-1600,-1000),Vector2(1600,-1000),Vector2(1600,1000),Vector2(-1600,1000)])
 floor_view.color = Color("38332e")
 floor_view.z_index = -100
 add_child(floor_view)
 var counter := Node2D.new()
 counter.position = Vector2(0,80)
 add_child(counter)
 var front := Polygon2D.new()
 front.polygon = PackedVector2Array([Vector2(-117.3,-26.64),Vector2(117.3,-26.64),Vector2(117.3,19.44),Vector2(-117.3,19.44)])
 front.color = Color("6e4b2a")
 counter.add_child(front)
 var top := Polygon2D.new()
 top.polygon = PackedVector2Array([Vector2(-117.3,-65.52),Vector2(117.3,-65.52),Vector2(117.3,-26.64),Vector2(-117.3,-26.64)])
 top.color = Color("9c6e42")
 counter.add_child(top)
 var mapping := SpatialMapping.new()
 for point in [Vector2(-55,35),Vector2(55,110)]:
  var motor := ActorMotor.new()
  add_child(motor)
  motor.configure(mapping,4.5)
  motor.teleport(&"kiosk",mapping.to_ground(point))
  var view := preload("res://game/presentation/character_view.tscn").instantiate() as CharacterView
  motor.add_child(view)
  view.present(motor.pose,Color("3d7a8a"),true)
 var camera := Camera2D.new()
 add_child(camera)
 camera.enabled = true
 var overlay := CanvasLayer.new()
 add_child(overlay)
 var label := Label.new()
 label.text = "اختبار ترتيب العمق — نفس الشخصية خلف الكاونتر وأمامه"
 label.position = Vector2(100,80)
 label.size = Vector2(1080,60)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_override("font",load("res://assets/fonts/Cairo.ttf"))
 label.add_theme_font_size_override("font_size",24)
 overlay.add_child(label)
 await get_tree().process_frame
 await get_tree().process_frame
 if OS.has_feature("web"): JavaScriptBridge.eval("window.spatialStatus={ready:true}")
