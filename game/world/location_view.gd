class_name LocationView
extends Node2D
var definition: LocationDefinition
var mapping: SpatialMapping
var session: GameSession
var navigation := KioskNavigation.new()
var station_views: Dictionary = {}
var _fan: FanView
var _sign: SignView
func configure(data: LocationDefinition, source: GameSession) -> void:
 definition = data
 session = source
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
 navigation.configure(data,mapping)
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
 for id in station_views:
  var job := session.cooking.job(StringName(id))
  if job: station_views[id].present({"stage":str(job.stage),"heat_elapsed":job.heat_elapsed,"brew_elapsed":job.brew_elapsed})
 if _fan: _fan.present(session.home.snapshot())
 if _sign: _sign.present(session.kiosk_open)
func interaction_targets() -> Array[InteractionTarget]:
 var targets: Array[InteractionTarget] = []
 for data in definition.data.interactions:
  if not _permitted(data.get("requires",{})): continue
  var target := InteractionTarget.new(StringName(data.id),Vector2(data.ground[0],data.ground[1]),float(data.radius))
  target.primary = data.primary
  if _permitted(data.get("secondary_requires",{})): target.secondary = data.get("secondary","")
  targets.append(target)
 return targets
func _permitted(rule: Dictionary) -> bool:
 return session.conditions.permits(rule)
