class_name PlacementPreview
extends Node2D
var controller: BuildController
var spaces: SpaceService
var items: ItemStore
var mapping: SpatialMapping
func configure(build: BuildController, space_service: SpaceService, item_store: ItemStore, projection: SpatialMapping) -> void:
 controller=build
 spaces=space_service
 items=item_store
 mapping=projection
 z_index=40
 controller.changed.connect(queue_redraw)
func _draw() -> void:
 if controller==null or not controller.active: return
 var definition: Dictionary = spaces.definitions().locations[str(controller.location_id)]
 var bounds: Array = definition.build_bounds
 var scale := float(definition.cell_size)
 var selected_definition: Dictionary={}
 if controller.request!=null:
  selected_definition=items.definition(StringName(items.get_item(controller.request.instance_id).definition_id))
 for cell in BuildingGeometry.cell_map(definition):
  var start := Vector2(definition.origin[0],definition.origin[1])+Vector2(cell)*scale
  var tile := Rect2(start,Vector2.ONE*scale)
  var valid := selected_definition.is_empty() or BuildingGeometry.validate_placement(definition,selected_definition,tile,controller.location_id).ok
  var corners := PackedVector2Array([mapping.to_canvas(start),mapping.to_canvas(start+Vector2(scale,0)),mapping.to_canvas(start+Vector2(scale,scale)),mapping.to_canvas(start+Vector2(0,scale))])
  draw_colored_polygon(corners,Color(0.2,0.6,0.65,0.12) if valid else Color(0.8,0.2,0.2,0.12))
 for x in range(ceili(bounds[0]/scale),floori(bounds[2]/scale)+1): draw_line(mapping.to_canvas(Vector2(x*scale,bounds[1])),mapping.to_canvas(Vector2(x*scale,bounds[3])),Color(1,0.85,0.5,0.2))
 for y in range(ceili(bounds[1]/scale),floori(bounds[3]/scale)+1): draw_line(mapping.to_canvas(Vector2(bounds[0],y*scale)),mapping.to_canvas(Vector2(bounds[2],y*scale)),Color(1,0.85,0.5,0.2))
 if controller.request==null: return
 var item := items.get_item(controller.request.instance_id)
 var box := GridPlacementRules.footprint(controller.request.snapshot(),items.definition(StringName(item.definition_id)),definition)
 var points := PackedVector2Array([mapping.to_canvas(box.position),mapping.to_canvas(Vector2(box.end.x,box.position.y)),mapping.to_canvas(box.end),mapping.to_canvas(Vector2(box.position.x,box.end.y))])
 draw_colored_polygon(points,Color(0.25,0.85,0.55,0.5) if controller.last_result.ok else Color(0.9,0.2,0.15,0.55))
 points.append(points[0])
 draw_polyline(points,Color.WHITE,2)
