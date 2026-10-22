class_name ConditionEvaluator
extends RefCounted
## Finite declarative queries; never invokes content-provided methods.
var _knowledge: KnowledgeBook
var _relationships: RelationshipStore
var _clock: GameClock
var _visitors: VisitorService
var _home: HomeService
var _player: ActorPose
var _facts: Array
var _actors: Array
var _locations: Array
func _init(knowledge: KnowledgeBook, relationships: RelationshipStore, clock: GameClock, visitors: VisitorService, home: HomeService, player: ActorPose, facts: Array, actors: Array, locations: Array = []) -> void:
 _knowledge = knowledge
 _relationships = relationships
 _clock = clock
 _visitors = visitors
 _home = home
 _player = player
 _facts = facts
 _actors = actors
 _locations = locations
func validate(rule: Variant, depth: int = 0) -> bool:
 if not rule is Dictionary or depth>24: return false
 if rule.is_empty(): return true
 if rule.size()!=1: return false
 var op: String = str(rule.keys()[0])
 var value: Variant = rule[op]
 match op:
  "all","any":
   if not value is Array or value.is_empty(): return false
   for part in value:
    if not validate(part,depth+1): return false
   return true
  "not": return validate(value,depth+1)
  "fact_known": return value is String and value in _facts
  "home_item_owned": return value == "fan"
  "relationship_at_least":
   return value is Dictionary and value.get("from") in _actors and value.get("to") in _actors and value.get("axis") is String and _relationships.threshold_valid(StringName(value.axis),value.get("value"))
  "visit_count_at_least":
   if value is Dictionary: return value.get("character_id") in _actors and ContentValidation.integer(value.get("value")) and value.value>=0
   return ContentValidation.integer(value) and value>=0
  "day_at_least": return ContentValidation.integer(value) and value>=1
  "time_window": return ContentValidation.vector(value,2) and value[0]>=0 and value[0]<=value[1] and value[1]<=1440
  "participants_available": return value is bool
  "distance_at_most":
   if value is Dictionary: return value.get("location_id") in _locations and ContentValidation.vector(value.get("ground"),2) and ContentValidation.number(value.get("value")) and value.value>=0
   return ContentValidation.number(value) and value>=0
 return false
func permits(rule: Dictionary, participants: PackedStringArray = PackedStringArray()) -> bool:
 if not validate(rule): return false
 if rule.is_empty(): return true
 var op: String = str(rule.keys()[0])
 var value: Variant = rule[op]
 match op:
  "all":
   for part in value:
    if not permits(part,participants): return false
   return true
  "any":
   for part in value:
    if permits(part,participants): return true
   return false
  "not": return not permits(value,participants)
  "fact_known": return _knowledge.has(StringName(value))
  "home_item_owned": return _home.has_fan
  "relationship_at_least": return _relationships.value(StringName(value.from),StringName(value.to),StringName(value.axis))>=float(value.value)
  "visit_count_at_least":
   return _visitors.visit_count(StringName(value.character_id))>=int(value.value) if value is Dictionary else _visitors.visit_count(&"amgad")>=int(value)
  "day_at_least": return _clock.day>=int(value)
  "time_window":
   var minute := fposmod(_clock.minutes,1440)
   return minute>=float(value[0]) and minute<=float(value[1])
  "participants_available":
   var available := not participants.is_empty()
   for id in participants: available = available and _visitors.is_available(StringName(id))
   return available == value
  "distance_at_most":
   if value is Dictionary: return str(_player.location_id)==value.location_id and _player.ground.distance_to(Vector2(value.ground[0],value.ground[1]))<=float(value.value)
   if participants.is_empty(): return false
   for id in participants:
    var visit: VisitState = _visitors.visits.get(id)
    if visit == null or visit.pose.location_id!=_player.location_id or visit.pose.ground.distance_to(_player.ground)>float(value): return false
   return true
 return false
