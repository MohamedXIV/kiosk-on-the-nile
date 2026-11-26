extends Control
## A presentation-only postcard made from the authored corniche. No GameSession,
## commands, saves, visitors or time advancement are involved.
var _world: Node2D
var _surface: SubViewportContainer
var _viewport: SubViewport
var _origin: Vector2
func configure(config: SessionConfig) -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var locations := config.section("locations")
 var data: Dictionary=locations.get("kiosk",{})
 if data.is_empty():return
 _surface=SubViewportContainer.new()
 _surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _surface.stretch=true
 add_child(_surface)
 _surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _viewport=SubViewport.new()
 _viewport.world_2d=World2D.new()
 _viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
 _viewport.gui_disable_input=true
 _surface.add_child(_viewport)
 var backdrop := ColorRect.new()
 backdrop.color=Color(data.background)
 backdrop.z_index=-1000
 backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _viewport.add_child(backdrop)
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _world=Node2D.new()
 _world.y_sort_enabled=true
 _viewport.add_child(_world)
 var mapping := SpatialMapping.new(config.section("spatial"))
 _origin=Vector2(data.canvas_origin[0],data.canvas_origin[1])
 var floor_view := WorldFloor.new()
 floor_view.z_index=-100
 _world.add_child(floor_view)
 floor_view.configure(data.floor,mapping,data.font_path)
 if data.has("water"):
  var river := RiverView.new()
  river.z_index=-110
  _world.add_child(river)
  river.configure(data.water,mapping)
  var boat := BoatView.new()
  boat.z_index=-105
  _world.add_child(boat)
  boat.configure(data.water.boat,mapping)
 for prop in data.props:_add_prop(prop,_world,mapping,Vector2.ZERO)
 var spaces: Dictionary=config.section("spaces").get("locations",{})
 var space: Dictionary=spaces.get("kiosk",{})
 for building in space.get("buildings",[]):
  var roof := BuildingView.new()
  _world.add_child(roof)
  roof.configure(space,building,mapping)
  # Show the counter and interior on the title, as in a gameplay cutaway.
  roof.hide()
 _viewport.size_changed.connect(_fit)
 _fit()
func _fit() -> void:
 if not is_instance_valid(_world):return
 var extent := Vector2(_viewport.size)
 var zoom := clampf(extent.x/1000.0,0.62,1.25)
 _world.scale=Vector2.ONE*zoom
 _world.position=Vector2(extent.x*0.5,extent.y*0.68)+_origin
func _add_prop(data: Dictionary,parent: Node2D,mapping: SpatialMapping,parent_ground: Vector2) -> void:
 var visual: Node2D
 match str(data.kind):
  "kettle":visual=KettleView.new()
  "grill":visual=GrillView.new()
  "sign":visual=SignView.new()
  "fan":visual=FanView.new()
  _:visual=ObliqueProp.new()
 var ground := Vector2(data.ground[0],data.ground[1])
 visual.position=mapping.to_canvas(ground-parent_ground,float(data.get("height_offset",0)))
 parent.add_child(visual)
 visual.configure(data,mapping)
 if visual is SignView:
  visual.present(false)
  if LocaleService.current:LocaleService.current.changed.connect(visual.present.bind(false))
 for child in data.get("children",[]):_add_prop(child,visual,mapping,ground)
