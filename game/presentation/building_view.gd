class_name BuildingView
extends Node2D
var _space: Dictionary
var _building: Dictionary
var _mapping: SpatialMapping
var _cells: Array[Vector2i]=[]
func configure(space: Dictionary, building: Dictionary, mapping: SpatialMapping) -> void:
 _space=space
 _building=building
 _mapping=mapping
 z_index=50
 var membership := BuildingGeometry.cell_map(space)
 for cell in membership:
  if membership[cell]==building.id:_cells.append(cell)
 queue_redraw()
func present(player_ground: Vector2, player_in_location: bool, arrangement_active: bool) -> void:
 visible=not arrangement_active and not (player_in_location and BuildingGeometry.building_at(_space,player_ground)==StringName(_building.id))
func _draw() -> void:
 if _mapping==null:return
 var scale := float(_space.cell_size)
 var height := float(_building.roof.height)
 var color := Color(_building.roof.color)
 var origin := Vector2(_space.origin[0],_space.origin[1])
 for cell in _cells:
  var point := origin+Vector2(cell)*scale
  var polygon := PackedVector2Array([_mapping.to_canvas(point,height),_mapping.to_canvas(point+Vector2(scale,0),height),_mapping.to_canvas(point+Vector2(scale,scale),height),_mapping.to_canvas(point+Vector2(0,scale),height)])
  draw_colored_polygon(polygon,color)
