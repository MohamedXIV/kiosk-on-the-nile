class_name SeatCatalog
extends RefCounted
## Read-only derived slots; rebuilt only when the owned layout changes.
var _spaces: SpaceService
var _items: ItemStore
var _revision: int=-1
var _slots: Dictionary={}
func configure(spaces: SpaceService, items: ItemStore) -> void:
 _spaces=spaces;_items=items;_revision=-1
func lookup(id: String) -> Dictionary:
 _refresh()
 return _slots.get(id,{})
func entries(location: StringName) -> Array:
 _refresh()
 return _slots.values().filter(func(slot):return slot.location_id==str(location))
func revision() -> int:
 _refresh()
 return _revision
func _refresh() -> void:
 if _spaces==null or _items==null or _revision==_spaces.revision:return
 var perf := RuntimePerformance.begin()
 _slots.clear();_revision=_spaces.revision
 var placements: Dictionary=_spaces.snapshot().placements
 var tables: Dictionary={}
 for id in placements:
  var item := _items.get_item(StringName(id))
  var definition := _items.definition(StringName(item.definition_id))
  if definition.get("gathering_surface",false):tables[id]={"location":placements[id].location_id,"ground":_spaces.ground(StringName(id))}
 for id in placements:
  var placed: Dictionary=placements[id]
  if placed.host_id!="":continue
  var item := _items.get_item(StringName(id))
  var definition := _items.definition(StringName(item.definition_id))
  var center := _spaces.ground(StringName(id))
  for seat: Dictionary in definition.get("seats",[]):
   var table_id := ""
   var distance := float(seat.table_radius)
   for other in tables:
    if tables[other].location!=placed.location_id:continue
    var candidate := center.distance_to(tables[other].ground)
    if candidate<distance or (is_equal_approx(candidate,distance) and str(other)<table_id):distance=candidate;table_id=other
   var slot_id := str(id)+":"+str(seat.id)
   _slots[slot_id]={"id":slot_id,"item_id":str(id),"location_id":str(placed.location_id),"access":center+turn(Vector2(seat.access[0],seat.access[1]),int(placed.rotation)),"anchor":center+turn(Vector2(seat.anchor[0],seat.anchor[1]),int(placed.rotation)),"facing":turn(Vector2(seat.facing[0],seat.facing[1]),int(placed.rotation)),"height":float(seat.height),"table_id":table_id}
 RuntimePerformance.finish("seat_catalog",perf)
static func turn(point: Vector2, rotation: int) -> Vector2:
 var result := point
 for i in range(rotation):result=Vector2(-result.y,result.x)
 return result
