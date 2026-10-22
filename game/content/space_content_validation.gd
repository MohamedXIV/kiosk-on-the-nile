class_name SpaceContentValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var spaces: Variant = bundle.get("spaces")
 var initial: Variant = bundle.get("initial_layout")
 if not spaces is Dictionary or not spaces.get("locations") is Dictionary or not spaces.get("base_solids") is Dictionary or not initial is Dictionary or not initial.get("placements") is Dictionary or not initial.get("instances") is Array: return ContentValidation.fail("spaces")
 if not spaces.get("labels") is Dictionary:return ContentValidation.fail("spaces.labels")
 for key in ["recipes","surface","inventory","care","clean","clean_item","sleep","door_open","door_close"]:
  if not spaces.labels.get(key) is String:return ContentValidation.fail("spaces.labels")
 var global_ids: Dictionary = {}
 for id in spaces.locations:
  var s: Variant = spaces.locations[id]
  if not s is Dictionary or not ContentValidation.number(s.get("cell_size")) or s.cell_size!=0.25 or not s.get("origin") is Array or s.origin.size()!=2: return ContentValidation.fail("spaces."+id)
  for field in ["build_bounds","navigation_bounds"]:
   if not s.get(field) is Array or s[field].size()!=4: return ContentValidation.fail("spaces."+id+"."+field)
   for value in s[field]:
    if not ContentValidation.number(value): return ContentValidation.fail("spaces.bounds")
   if s[field][0]>=s[field][2] or s[field][1]>=s[field][3]: return ContentValidation.fail("spaces.bounds")
  if not s.get("exits") is Array or s.exits.is_empty(): return ContentValidation.fail("spaces.exits")
  for point in s.exits:
   if not point is Array or point.size()!=2 or not ContentValidation.number(point[0]) or not ContentValidation.number(point[1]): return ContentValidation.fail("spaces.exits")
  var ids: Dictionary = {}
  for field in ["walls","doors"]:
   if not s.get(field) is Array: return ContentValidation.fail("spaces.structure")
   for edge in s[field]:
    if not edge is Dictionary or not edge.get("id") is String or ids.has(edge.id) or not edge.get("cell") is Array or edge.cell.size()!=2 or not ContentValidation.integer(edge.cell[0]) or not ContentValidation.integer(edge.cell[1]) or not edge.get("axis") in ["x","y"] or not ContentValidation.integer(edge.get("length")) or edge.length<1: return ContentValidation.fail("spaces.structure")
    if global_ids.has(edge.id): return ContentValidation.fail("spaces.duplicate_structure_id")
    global_ids[edge.id]=true
    ids[edge.id]=true
  if not s.get("rooms") is Array: return ContentValidation.fail("spaces.rooms")
  for door in s.doors:
   if not door.get("open") is bool or not door.get("usable") is bool: return ContentValidation.fail("spaces.door")
   var door_start := Vector2(door.cell[0],door.cell[1])
   var door_end := door_start+(Vector2(door.length,0) if door.axis=="x" else Vector2(0,door.length))
   var touches_wall := false
   for wall in s.walls:
    var wall_start := Vector2(wall.cell[0],wall.cell[1])
    var wall_end := wall_start+(Vector2(wall.length,0) if wall.axis=="x" else Vector2(0,wall.length))
    if door.axis==wall.axis:
     if door_start.is_equal_approx(wall_end) or door_end.is_equal_approx(wall_start): touches_wall=true
     var parallel := door_start.y==wall_start.y if door.axis=="x" else door_start.x==wall_start.x
     var overlap := minf(door_end.x,wall_end.x)>maxf(door_start.x,wall_start.x) if door.axis=="x" else minf(door_end.y,wall_end.y)>maxf(door_start.y,wall_start.y)
     if parallel and overlap: return ContentValidation.fail("spaces.door_overlaps_wall")
   if not touches_wall: return ContentValidation.fail("spaces.door_without_wall")
  var cells: Dictionary = {}
  var room_ids: Dictionary = {}
  for room in s.rooms:
   if not room is Dictionary or not room.get("id") is String or not room.get("cells") is Array or room.cells.is_empty(): return ContentValidation.fail("spaces.rooms")
   if room_ids.has(room.id): return ContentValidation.fail("spaces.duplicate_room")
   room_ids[room.id]=true
   for cell in room.cells:
    if not cell is Array or cell.size()!=2 or not ContentValidation.integer(cell[0]) or not ContentValidation.integer(cell[1]) or cells.has(str(cell)): return ContentValidation.fail("spaces.room_cells")
    cells[str(cell)]=room.id
 for id in bundle.items:
  var value: Dictionary = bundle.items[id]
  if value.kind not in ["equipment","furniture"]: continue
  if not value.get("footprint") is Array or value.footprint.size()!=2: return ContentValidation.fail("items.footprint")
  for size in value.footprint:
   if not ContentValidation.integer(size) or size<1: return ContentValidation.fail("items.footprint")
 var instances: Dictionary = {}
 for instance in initial.instances:
  if not instance is Dictionary or not instance.get("id") is String or instances.has(instance.id) or not bundle.items.has(str(instance.get("definition_id",""))): return ContentValidation.fail("initial_layout.instances")
  instances[instance.id]=true
 if instances.size()!=initial.placements.size(): return ContentValidation.fail("initial_layout.placements")
 for id in initial.placements:
  var p: Variant = initial.placements[id]
  if not instances.has(id) or not p is Dictionary or p.get("instance_id")!=id or not spaces.locations.has(str(p.get("location_id",""))) or not p.get("cell") is Array or p.cell.size()!=2: return ContentValidation.fail("initial_layout.placement")
 return ActionResult.success()
