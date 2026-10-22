class_name SupplyService
extends RefCounted
## Entry points share travel and commerce; no instantaneous stock/furniture grants.
var _travel: TravelService
var _home: HomeService
var _knowledge: KnowledgeBook
func _init(travel: TravelService, home: HomeService, knowledge: KnowledgeBook) -> void:
 _travel=travel
 _home=home
 _knowledge=knowledge
func buy_stock() -> ActionResult:
 return _travel.depart(&"market")
func buy_fan() -> ActionResult:
 if not _knowledge.has(&"KNOWN_CHEAP_FAN"):return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"fan_unknown")
 if _home.has_fan:return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"already_owned")
 return _travel.depart(&"appliances")
