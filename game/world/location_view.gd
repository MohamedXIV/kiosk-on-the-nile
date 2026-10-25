class_name LocationView
extends Node2D
var definition: LocationDefinition
var mapping: SpatialMapping
var session: GameSession
var navigation := KioskNavigation.new()
var station_views: Dictionary = {}
var _fan: FanView
var _sign: SignView
var _geometry: Array[Node] = []
var _surface_foods: Dictionary = {}
var _item_visuals: Dictionary = {}
var _buildings: Array[BuildingView]=[]
var _authored_text: Dictionary={}
var _action_text: Dictionary={}
var _surface_text: Dictionary={}
func configure(data: LocationDefinition, source: GameSession) -> void:
 session = source
 _authored_text=source.config.section("locations").get(str(data.id),{})
 _action_text=source.spaces.definitions().labels
 _surface_text=source.config.section("ui")
 definition = LocationDefinition.new(data.id,SpaceSceneAdapter.location(data.data,data.id,source.spaces,source.items))
 data = definition
 mapping = SpatialMapping.new(source.config.section("spatial"))
 position = Vector2(data.data.canvas_origin[0],data.data.canvas_origin[1])
 y_sort_enabled = true
 var background := Polygon2D.new()
 background.polygon = PackedVector2Array([Vector2(-10000,-10000),Vector2(10000,-10000),Vector2(10000,10000),Vector2(-10000,10000)])
 background.color = Color(data.data.background)
 background.z_index = -1000
 add_child(background)
 var floor_view := WorldFloor.new()
 floor_view.z_index = -100
 add_child(floor_view)
 floor_view.configure(data.data.floor,mapping,data.data.font_path)
 var floor_grime := HygieneView.new()
 floor_view.add_child(floor_grime)
 floor_grime.configure(StringName("floor:"+str(data.id)),session.hygiene,250)
 if data.data.has("water"):
  var river := RiverView.new()
  river.z_index = -110
  add_child(river)
  river.configure(data.data.water,mapping)
  var boat := BoatView.new()
  boat.z_index = -105
  add_child(boat)
  boat.configure(data.data.water.boat,mapping)
 for prop in data.data.props: _add_visual(prop,self,Vector2.ZERO)
 var space: Dictionary=session.spaces.definitions().locations[str(data.id)]
 for building in space.buildings:
  var roof := BuildingView.new()
  add_child(roof)
  roof.configure(space,building,mapping)
  _buildings.append(roof)
 for prop in data.data.props:
  if prop.kind=="lamp":
   var light := WarmLight.new()
   light.position = mapping.to_canvas(Vector2(prop.ground[0],prop.ground[1]))
   light.configure(source.config.section("atmosphere").light)
   add_child(light)
 var solids := Node2D.new()
 solids.name = "Solids"
 add_child(solids)
 for solid in data.data.solids: _add_solid(solid,solids,1)
 var bounds: Array = data.data.player_bounds
 for box in [[bounds[0]-1,bounds[1]-1,bounds[0],bounds[3]+1],[bounds[2],bounds[1]-1,bounds[2]+1,bounds[3]+1],[bounds[0],bounds[1]-1,bounds[2],bounds[1]],[bounds[0],bounds[3],bounds[2],bounds[3]+1]]:
  _add_solid({"kind":"rect","rect":box},solids,4)
 for container in session.items.snapshot().containers.values():
  if container.kind!="surface" or container.location_id!=str(data.id) or session.spaces.placement(StringName(container.host_id)).is_empty(): continue
  var view := HeldItemView.new()
  var ground := session.spaces.ground(StringName(container.host_id))
  var host := session.items.get_item(StringName(container.host_id))
  var height := float(session.items.definition(StringName(host.definition_id)).get("height",0.96))
  view.position=Vector2(0,-height*mapping.height_scale+34)
  if _item_visuals.has(container.host_id):_item_visuals[container.host_id].add_child(view)
  else:
   view.position+=mapping.to_canvas(ground)
   add_child(view)
  _surface_foods[container.id]=view
 navigation.configure(data,mapping)
 _geometry.assign(get_children())
func _add_solid(data: Dictionary, parent: Node, layer: int) -> void:
 var body := StaticBody2D.new()
 body.collision_layer = layer
 var collider := CollisionShape2D.new()
 collider.shape = FootprintGeometry.shape(data,mapping)
 body.add_child(collider)
 parent.add_child(body)
func _add_visual(data: Dictionary, parent: Node2D, parent_ground: Vector2) -> void:
 var visual: Node2D
 match data.kind:
  "kettle": visual = KettleView.new()
  "grill": visual = GrillView.new()
  "fan": visual = FanView.new(); _fan = visual
  "sign": visual = SignView.new(); _sign = visual
  _: visual = ObliqueProp.new()
 var ground := Vector2(data.ground[0],data.ground[1])
 visual.position = mapping.to_canvas(ground-parent_ground,float(data.get("height_offset",0)))
 parent.add_child(visual)
 visual.configure(data,mapping)
 if data.has("instance_id"):
  _item_visuals[data.instance_id]=visual
  var hygiene_view := HygieneView.new()
  visual.add_child(hygiene_view)
  hygiene_view.configure(StringName(data.instance_id),session.hygiene,float(data.get("size",[1,1,1])[0])*mapping.x_scale)
  var item := session.items.get_item(StringName(data.instance_id))
  if item.get("kind")=="equipment" and not data.has("station_id"):
   var state_view := EquipmentView.new()
   visual.add_child(state_view)
   state_view.position.y=-float(data.get("size",[0,0,1])[2])*mapping.height_scale-12
   state_view.configure(StringName(data.instance_id),session)
 if data.has("station_id"):
  station_views[data.station_id] = visual
  var vapour := StationVapour.new()
  vapour.position.y = -30
  vapour.job = session.cooking.job(StringName(data.station_id))
  vapour.data = session.config.section("atmosphere").steam
  visual.add_child(vapour)
 for child in data.get("children",[]): _add_visual(child,visual,ground)
func _process(_delta: float) -> void:
 if session == null: return
 visible = session.location_id == definition.id
 for roof in _buildings:roof.present(session.player_ground,session.location_id==definition.id,session.build.active and session.build.location_id==definition.id)
 for id in station_views:
  var job := session.cooking.job(StringName(id))
  if job:
   station_views[id].present({"stage":str(job.stage),"heat_elapsed":job.heat_elapsed,"brew_elapsed":job.brew_elapsed})
   for child in station_views[id].get_children():
    if child is StationVapour:child.job=job
 if _fan: _fan.present(session.home.snapshot())
 if _sign: _sign.present(session.kiosk_open)
 for slot in _surface_foods:
  var contents := session.items.items_in(StringName(slot))
  _surface_foods[slot].present_record(contents[0] if not contents.is_empty() else {})
func interaction_targets() -> Array[InteractionTarget]:
 var targets: Array[InteractionTarget] = []
 for data in definition.data.interactions:
  if not _permitted(data.get("requires",{})): continue
  var target := InteractionTarget.new(StringName(data.id),Vector2(data.ground[0],data.ground[1]),float(data.radius))
  target.primary = WorldText.interaction(session,str(definition.id),data,"primary",_authored_text,_action_text)
  if data.get("action")=="surface":
   var slots := session.items.items_in(StringName(data.slot_id))
   var key := "surface_put" if not session.inventory.held_id().is_empty() else "surface_take" if not slots.is_empty() else "surface_empty"
   target.primary = ItemText.source("ui."+key,str(_surface_text.get(key,key)))
  if _permitted(data.get("secondary_requires",{})): target.secondary = WorldText.interaction(session,str(definition.id),data,"secondary",_authored_text,_action_text)
  targets.append(target)
 return targets
func _permitted(rule: Dictionary) -> bool:
 return session.conditions.permits(rule)

func refresh_layout() -> void:
 for child in _geometry:
  if is_instance_valid(child):
   remove_child(child)
   child.free()
 _geometry.clear()
 station_views.clear()
 _surface_foods.clear()
 _item_visuals.clear()
 _buildings.clear()
 _fan = null
 _sign = null
 var base := LocationDefinition.new(definition.id,session.config.section("locations")[str(definition.id)])
 # Actor nodes stay alive. Only retain freshly generated geometry for next refresh.
 var actors := get_children()
 configure(base,session)
 for actor in actors: _geometry.erase(actor)
