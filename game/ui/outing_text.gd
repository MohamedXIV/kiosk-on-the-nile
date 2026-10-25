class_name OutingText
extends RefCounted
## Presentation only; source guards keep externally edited definitions truthful.
static func t(key: String, args: Dictionary = {}) -> String:return UiText.localized("outings."+key,args,key)
static func offer(shop: StringName, value: Dictionary, field: String) -> String:
 return ItemText.source("shop."+str(shop)+".offer."+str(value.id)+"."+field,str(value.get(field,"")))
static func route(value: Dictionary, id: String) -> String:
 return ItemText.source("route."+id,str(value.get("label","")))
static func topic(value: Dictionary) -> String:
 return ItemText.source("topic."+str(value.id),str(value.label))
static func order(session: GameSession, id: StringName) -> String:
 var food := session.cooking.foods.definition(id)
 return ItemText.source("food."+str(id)+".menu",str(food.get("menu_label",id)))
static func manual_topic(value: Dictionary) -> String:
 var key := str(value.key)
 return ItemText.source("topic."+key.trim_prefix("social:") if key.begins_with("social:") else "manual_topic."+key,str(value.label))
