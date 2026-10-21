class_name InteractionSelector
extends RefCounted
static func nearest(ground: Vector2, targets: Array[InteractionTarget]) -> InteractionTarget:
 var closest: InteractionTarget
 var distance: float = INF
 for target in targets:
  var candidate := ground.distance_to(target.ground)
  if target.available and candidate <= target.radius and candidate < distance:
   closest = target
   distance = candidate
 return closest
