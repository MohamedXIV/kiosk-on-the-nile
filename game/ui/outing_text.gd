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

static func serving_reference(selection: Dictionary) -> Dictionary:
 var variant := str(selection.get("variant_id",""))
 var reference := {"text_ref":"menu.serving","parameters":{"food":{"text_ref":"menu.food."+variant.get_slice("/",0)},"format":{"text_ref":"serving."+variant.get_slice("/",1)},"mode":{"text_ref":"serving."+variant.get_slice("/",2)}}}
 for id in selection.get("additions",[]):reference={"text_ref":"menu.with_addition","parameters":{"base":reference,"addition":{"text_ref":"addition."+str(id)}}}
 return reference
static func serving(session: GameSession, selection: Dictionary) -> String:
 if str(selection.get("variant_id","")).is_empty():return order(session,StringName(str(selection.get("food_id",""))))
 var ref := serving_reference(selection)
 return UiText.localized(str(ref.text_ref),ref.parameters,"")
