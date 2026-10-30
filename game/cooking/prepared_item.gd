class_name PreparedItem
extends RefCounted
var id: StringName
var recipe_id: StringName
var variant_id: StringName
var food_id: StringName
var sugar_id: StringName
var freshness: Dictionary={}
var initial_quality: float=0
var prepared_at: float=-1
var batch_id: StringName
var method: StringName
var heat: StringName=&"off"
var serving_format: StringName
var consumption_mode: StringName=&"here"
var additions: PackedStringArray=[]
var quality_score: int = 0
var quality_key: StringName
func snapshot() -> Dictionary:
 return {"freshness":freshness.duplicate(true),"initial_quality":initial_quality,"prepared_at":prepared_at,"batch_id":str(batch_id),"method":str(method),"heat":str(heat),"serving_format":str(serving_format),"consumption_mode":str(consumption_mode),"additions":Array(additions),"id":str(id),"recipe_id":str(recipe_id),"variant_id":str(variant_id),"food_id":str(food_id),"sugar_id":str(sugar_id),"quality_score":quality_score,"quality_key":str(quality_key)}
static func from_dict(data: Dictionary) -> PreparedItem:
 var item := PreparedItem.new()
 item.freshness=data.get("freshness",{}).duplicate(true)
 item.initial_quality=float(data.get("initial_quality",0))
 item.prepared_at=float(data.get("prepared_at",-1))
 item.batch_id=StringName(str(data.get("batch_id","")))
 item.method=StringName(str(data.get("method","")))
 item.heat=StringName(str(data.get("heat","off")))
 item.serving_format=StringName(str(data.get("serving_format","")))
 item.consumption_mode=StringName(str(data.get("consumption_mode","here")))
 item.additions=PackedStringArray(data.get("additions",[]))
 item.id = StringName(data.id)
 item.recipe_id = StringName(data.recipe_id)
 item.variant_id=StringName(str(data.get("variant_id","")))
 item.food_id = StringName(data.food_id)
 item.sugar_id = StringName(data.get("sugar_id",""))
 item.quality_score = int(data.quality_score)
 item.quality_key = StringName(data.quality_key)
 return item
