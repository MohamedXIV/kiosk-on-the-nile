class_name WorldText
extends RefCounted
## Read-only projection over authored interaction identity and generated piece actions.
static func interaction(session: GameSession, location_id: String, data: Dictionary, field: String, authored: Dictionary, labels: Dictionary) -> String:
 var source := str(data.get(field,""))
 if source.is_empty():return ""
 for original in authored.get("interactions",[]):
  if original.id==data.get("source_interaction_id",data.id) and original.get(field,"")==source:return ItemText.source("location."+location_id+".interaction."+str(original.id)+"."+field,source)
 var action := str(data.get("action",""))
 if field=="primary" and action=="clean" and str(data.id).begins_with("care:"):
  var item := session.items.get_item(StringName(str(data.get("instance_id",""))))
  var raw_name := str(session.items.definition(StringName(str(item.get("definition_id","")))).get("label",""))
  if source==str(labels.clean_item).format({"item":raw_name}):return ItemText.source("space.action.clean_item",str(labels.clean_item),{"item":ItemText.definition(session,str(item.definition_id))})
 if field=="primary" and data.has("instance_id"):
  var item := session.items.get_item(StringName(str(data.instance_id)))
  var definition := session.items.definition(StringName(str(item.get("definition_id",""))))
  if source==definition.get("label"):return ItemText.definition(session,str(item.definition_id))
 for key in labels:
  if labels[key]==source:return ItemText.source("space.action."+str(key),source)
 return source
