class_name SpaceSceneAdapter
extends RefCounted
static func location(source: Dictionary, location_id: StringName, spaces: SpaceService, items: ItemStore) -> Dictionary:
 var result := source.duplicate(true)
 var labels: Dictionary=spaces.definitions().labels
 result.solids = spaces.solids(location_id)
 var props: Array = []
 for prop in result.props:
  if not prop.get("owned",false): props.append(prop)
 result.props = props
 var interactions: Array = []
 for target in result.interactions:
  if not target.has("instance_id"): interactions.append(target)
 result.interactions = interactions
 var prop_by_id: Dictionary = {}
 var mounted: Array[Dictionary] = []
 var definitions: Dictionary = spaces.definitions().locations
 var space: Dictionary = definitions[str(location_id)]
 result.floor["building_tiles"]=[]
 for cell in BuildingGeometry.cell_map(space):
  var corner := Vector2(space.origin[0],space.origin[1])+Vector2(cell)*float(space.cell_size)
  result.floor.building_tiles.append([corner.x,corner.y,corner.x+float(space.cell_size),corner.y+float(space.cell_size)])
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
  prop["height_offset"] = float(items.definition(StringName(items.get_item(StringName(record.host_id)).definition_id)).get("height",0.96)) if record.host_id!="" else 0.0
  if definition.has("station_id"): prop["station_id"] = definition.station_id
  prop["instance_id"]=id
  prop_by_id[id]=prop
  if record.host_id=="":result.props.append(prop)
  else:mounted.append({"host_id":record.host_id,"prop":prop})
  var mapped := false
  for target in source.interactions:
   if target.get("instance_id")==id or (target.get("instance_id")=="legacy_fan" and item.definition_id=="fan"):
    var moved: Dictionary = target.duplicate(true)
    moved["source_interaction_id"]=target.id
    moved.ground = [ground.x,ground.y]
    moved.instance_id=id
    if definition.get("behavior")=="toggle_equipment":
     moved.id="equipment:"+id
     moved.action="toggle_equipment"
    if definition.get("surface",false):moved.merge({"secondary":labels.care,"secondary_action":"recipes"},true)
    elif not moved.has("secondary_action"):moved.merge({"secondary":labels.clean,"secondary_action":"clean"})
    result.interactions.append(moved)
    mapped=true
  if item.kind=="furniture" and not mapped and not definition.get("surface",false) and definition.get("behavior","")=="":
   result.interactions.append({"id":"care:"+id,"instance_id":id,"ground":[ground.x,ground.y],"radius":1.2,"primary":str(labels.clean_item).format({"item":str(definition.label)}),"action":"clean"})
  if definition.get("behavior")=="toggle_equipment" and not mapped:
   result.interactions.append({"id":"equipment:"+id,"instance_id":id,"ground":[ground.x,ground.y],"radius":1.2,"primary":str(definition.label),"action":"toggle_equipment","secondary":labels.clean,"secondary_action":"clean"})
  if definition.has("container"):
   result.interactions.append({"id":"storage:"+id,"instance_id":id,"ground":[ground.x,ground.y],"radius":1.3,"primary":labels.inventory,"action":"inventory","container_id":id+":"+str(definition.container.kind),"secondary":labels.care,"secondary_action":"recipes"})
  if definition.get("behavior")=="sleep" and not mapped:
   result.interactions.append({"id":"bed:"+id,"instance_id":id,"ground":[ground.x,ground.y],"radius":1.3,"primary":labels.sleep,"action":"sleep","secondary":labels.clean,"secondary_action":"clean"})
  if item.kind=="equipment" and not definition.has("station_id") and not definition.has("container"):
   result.interactions.append({"id":"recipe:"+id,"ground":[ground.x,ground.y],"radius":1.3,"primary":str(definition.label),"action":"recipes","instance_id":id})
  var mounted_device := false
  for placed in spaces.snapshot().placements.values():
   if placed.host_id==id:mounted_device=true;break
  if definition.get("surface",false) and not mounted_device:
   result.interactions.append({"id":"surface:"+id,"ground":[ground.x,ground.y],"radius":1.1,"primary":labels.surface,"secondary":labels.care,"secondary_action":"recipes","action":"surface","instance_id":id,"slot_id":id+":top"})
 for child in mounted:
  if prop_by_id.has(child.host_id):
   var host: Dictionary=prop_by_id[child.host_id]
   if not host.has("children"):host["children"]=[]
   host.children.append(child.prop)
 for door in space.doors:
  var opened: bool = spaces.snapshot().door_states.get(door.id,door.open)
  var point := Vector2(door.cell[0],door.cell[1])*float(space.cell_size)+Vector2(space.origin[0],space.origin[1])
  point+=(Vector2(0,float(door.length)) if door.axis=="y" else Vector2(float(door.length),0))*float(space.cell_size)/2
  if not opened:
   result.props.append({"kind":"box","ground":[point.x,point.y],"size":[0.08 if door.axis=="y" else float(door.length)*space.cell_size,float(door.length)*space.cell_size if door.axis=="y" else 0.08,BuildingGeometry.edge_height(space,door)],"top":"#99764e","front":"#6c5032"})
  result.interactions.append({"id":door.id,"ground":[point.x,point.y],"radius":0.9,"primary":labels.door_close if opened else labels.door_open,"action":"door","door_id":door.id,"opened":opened})
 for wall in space.walls:
  var point := Vector2(wall.cell[0],wall.cell[1])*float(space.cell_size)+Vector2(space.origin[0],space.origin[1])
  var size := Vector2(0.08,float(wall.length)*space.cell_size) if wall.axis=="y" else Vector2(float(wall.length)*space.cell_size,0.08)
  point += size/2
  var height := BuildingGeometry.edge_height(space,wall)
  for building in space.buildings:
   for window in building.get("service_windows",[]):
    if window.wall_id==wall.id:height=float(window.sill_height)
  result.props.append({"kind":"box","ground":[point.x,point.y],"size":[size.x,size.y,height],"top":"#9c8c79" if location_id==&"rooftop" else "#405856","front":"#736555" if location_id==&"rooftop" else "#243c3a"})
 # Standing markers follow the actual piece, with the authored local offset.
 for marker_id in space.get("marker_bindings",{}):
  var binding: Dictionary = space.marker_bindings[marker_id]
  if spaces.placement(StringName(binding.instance_id)).is_empty(): continue
  var anchor := spaces.ground(StringName(binding.instance_id))+Vector2(binding.offset[0],binding.offset[1])
  result.markers[marker_id]=[anchor.x,anchor.y]
 return result
