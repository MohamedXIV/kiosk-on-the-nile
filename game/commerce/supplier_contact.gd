class_name SupplierContact
extends RefCounted
var _session: GameSession
var current: ResidentialRecord
var host_id: String=""
var next_id: int=1
var panel_requested: bool=false
func configure(session: GameSession) -> void:
 _session=session
 session.spaces.changed.connect(func(_location,_revision):tick())
 session.items.changed.connect(func(_revision):tick())
func points() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for id in _session.config.section("suppliers").phone_hosts:
  var p := _session.spaces.placement(StringName(id))
  if not p.is_empty() and _session.items.get_item(StringName(id)).get("container_id")==str(p.location_id)+"_world":result.append({"host_id":id,"location_id":p.location_id,"ground":_session.spaces.ground(StringName(id))})
 return result
func near_point(id: String) -> bool:
 for point in points():
  if point.host_id==id and point.location_id==str(_session.location_id) and point.ground.distance_to(_session.player_ground)<=float(_session.config.section("suppliers").phone_radius):return true
 return false
func available() -> bool:
 if current==null or not near_point(host_id):return false
 for point in points():
  if point.host_id==host_id:return current.pose.location_id==StringName(point.location_id) and current.pose.ground.distance_to(point.ground)<=0.01
 return false
func begin(id: String) -> ActionResult:
 if not near_point(id):return _fail()
 if _session.personal.active() and (current==null or not _session.personal.holds_visit(current.id)):return _fail()
 if current==null:
  current=ResidentialRecord.new();current.id=StringName("phone_%d" % next_id);next_id+=1
  current.character_id=&"fathi";current.phase=&"staying";current.pose.location_id=_session.location_id
  host_id=id
  for point in points():
   if point.host_id==id:current.pose.ground=point.ground
 var result := await _session.personal.open_for(current.id)
 if result.ok and _session.personal.view().get("conversation")==null:result=await _session.personal.select_topic("supplier")
 return result
func tick(_frame: Dictionary = {}) -> void:
 if current!=null and not available():close()
func close() -> void:
 panel_requested=false
 if current!=null and _session.personal.holds_visit(current.id):_session.personal.leave()
 current=null;host_id=""
func snapshot() -> Dictionary:return {"current":current.snapshot() if current!=null else {},"host_id":host_id,"next_id":next_id,"panel_requested":panel_requested}
func restore(data: Dictionary) -> ActionResult:
 if not data.get("current") is Dictionary or not data.get("host_id") is String or not ContentValidation.integer(data.get("next_id")) or data.next_id<1 or not data.get("panel_requested") is bool:return _fail()
 current=null;host_id=data.host_id;next_id=int(data.next_id);panel_requested=bool(data.panel_requested)
 if data.current.is_empty():return ActionResult.success() if host_id=="" and not panel_requested else _fail()
 var r: Dictionary=data.current
 var suffix := str(r.get("id","")).trim_prefix("phone_")
 if not str(r.get("id","")).begins_with("phone_") or not suffix.is_valid_int() or int(suffix)<1 or int(suffix)>=next_id or r.get("character_id")!="fathi" or r.get("phase")!="staying" or not near_point(host_id):return _fail()
 current=ResidentialRecord.new();current.id=StringName(r.id);current.character_id=&"fathi";current.phase=&"staying"
 if not current.pose.restore(r.get("pose",{})).ok or current.pose.location_id!=_session.location_id:return _fail()
 for point in points():
  if point.host_id==host_id and current.pose.ground.distance_to(point.ground)>0.01:return _fail()
 return ActionResult.success()
func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"supplier_contact_required")
