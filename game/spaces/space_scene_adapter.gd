class_name SpaceSceneAdapter
extends RefCounted
static func location(source: Dictionary, location_id: StringName, spaces: SpaceService, items: ItemStore) -> Dictionary:
 var result := source.duplicate(true)
 result.solids = spaces.solids(location_id)
 var props: Array = []
 for prop in result.props:
  if not prop.get("owned",false): props.append(prop)
 result.props = props
 var interactions: Array = []
 for target in result.interactions:
  if not target.has("instance_id"): interactions.append(target)
 result.interactions = interactions
 var definitions: Dictionary = spaces.definitions().locations
 var space: Dictionary = definitions[str(location_id)]
 for id in spaces.snapshot().placements:
  var record := spaces.placement(StringName(id))
  if record.location_id!=str(location_id): continue
  var item := items.get_item(StringName(id))
  var definition := items.definition(StringName(item.definition_id))
  var ground := spaces.ground(StringName(id))
  var box := GridPlacementRules.footprint(record,definition,space)
  var prop: Dictionary = definition.get("visual",{"kind":"box","top":definition.get("color","#98714b"),"front":"#654b32"}).duplicate(true)
  prop["ground"] = [ground.x,ground.y]
  prop["size"] = [box.size.x,box.size.y,float(definition.get("height",0.8))]
  prop["height_offset"] = float(definition.get("mount_height",0.96)) if record.host_id!="" else 0.0
  if definition.has("station_id"): prop["station_id"] = definition.station_id
  result.props.append(prop)
  for target in source.interactions:
   if target.get("instance_id")==id or (target.get("instance_id")=="legacy_fan" and item.definition_id=="fan"):
    var moved: Dictionary = target.duplicate(true)
    moved.ground = [ground.x,ground.y]
    result.interactions.append(moved)
  if definition.get("surface",false):
   result.interactions.append({"id":"surface:"+id,"ground":[ground.x,ground.y],"radius":1.1,"primary":"سطح التحضير","secondary":"","action":"surface","instance_id":id,"slot_id":id+":top"})
 for door in space.doors:
  var opened: bool = spaces.snapshot().door_states.get(door.id,door.open)
  var point := Vector2(door.cell[0],door.cell[1])*float(space.cell_size)+Vector2(space.origin[0],space.origin[1])
  if not opened:
   result.props.append({"kind":"box","ground":[point.x,point.y],"size":[0.08 if door.axis=="y" else float(door.length)*space.cell_size,float(door.length)*space.cell_size if door.axis=="y" else 0.08,1.7],"top":"#99764e","front":"#6c5032"})
  result.interactions.append({"id":door.id,"ground":[point.x,point.y],"radius":0.9,"primary":"اقفل الباب" if opened else "افتح الباب","action":"door","door_id":door.id,"opened":opened})
 for wall in space.walls:
  var point := Vector2(wall.cell[0],wall.cell[1])*float(space.cell_size)+Vector2(space.origin[0],space.origin[1])
  var size := Vector2(0.08,float(wall.length)*space.cell_size) if wall.axis=="y" else Vector2(float(wall.length)*space.cell_size,0.08)
  point += size/2
  result.props.append({"kind":"box","ground":[point.x,point.y],"size":[size.x,size.y,1.5],"top":"#9c8c79","front":"#736555"})
 # Standing markers follow the actual piece, with the authored local offset.
 for marker_id in space.get("marker_bindings",{}):
  var binding: Dictionary = space.marker_bindings[marker_id]
  if spaces.placement(StringName(binding.instance_id)).is_empty(): continue
  var anchor := spaces.ground(StringName(binding.instance_id))+Vector2(binding.offset[0],binding.offset[1])
  result.markers[marker_id]=[anchor.x,anchor.y]
 return result
