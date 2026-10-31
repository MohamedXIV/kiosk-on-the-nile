class_name FoodFreshness
extends RefCounted
## Pure accumulated exposure. Changing storage/heat changes only future ageing.
const RATES := {"ambient":1.0,"warm":0.5,"cold":0.25}
static func begin(at: float, context: String="ambient") -> Dictionary:
 return {"at":at,"exposure":0.0,"context":context}
static func exposure(state: Dictionary, now: float) -> float:
 return float(state.exposure)+maxf(0,now-float(state.at))*float(RATES[state.context])
static func transition(state: Dictionary, context: String, now: float) -> Dictionary:
 return {"at":now,"exposure":exposure(state,now),"context":context}
static func view(item: Dictionary, now: float, definitions: Dictionary) -> Dictionary:
 var data: Dictionary=definitions.get(str(item.get("food_id","")),{}).get("freshness",{})
 if data.is_empty() or not ContentValidation.bounded(item.get("initial_quality"),0,100) or not ContentValidation.number(item.get("prepared_at")) or not valid(item.get("freshness"),float(item.get("prepared_at",-1)),now):return {"sellable":false,"stage":"unservable","initial_quality":0.0,"present_quality":0.0,"grade":0,"age":0.0}
 var age := exposure(item.freshness,now)
 var initial := float(item.initial_quality)
 var factor := 1.0
 if age>float(data.fresh_until):factor=lerpf(1.0,0.88,clampf((age-float(data.fresh_until))/(float(data.declined_after)-float(data.fresh_until)),0,1))
 if age>float(data.declined_after):factor=lerpf(0.88,0.60,clampf((age-float(data.declined_after))/(float(data.unservable_after)-float(data.declined_after)),0,1))
 var sellable := age<float(data.unservable_after) and initial>0
 var quality := initial*factor if sellable else 0.0
 return {"sellable":sellable,"stage":"unservable" if not sellable else "fresh" if age<=float(data.fresh_until) else "settled" if age<float(data.declined_after) else "declined","initial_quality":initial,"present_quality":quality,"grade":RecipeProcesses.grade_for(quality),"age":age}
static func valid(state: Variant, prepared_at: float, now: float) -> bool:
 if not state is Dictionary or not CharacterLifeValidation.keys(state,["at","exposure","context"]) or not state.context is String or not RATES.has(state.context):return false
 return prepared_at>=0 and ContentValidation.bounded(state.at,prepared_at,now) and ContentValidation.bounded(state.exposure,0,maxf(0,float(state.at)-prepared_at)+0.001)
static func validate_curve(data: Variant) -> bool:
 if not data is Dictionary or not CharacterLifeValidation.keys(data,["fresh_until","declined_after","unservable_after"]):return false
 return ContentValidation.bounded(data.fresh_until,1,1440) and ContentValidation.bounded(data.declined_after,float(data.fresh_until)+1,2880) and ContentValidation.bounded(data.unservable_after,float(data.declined_after)+1,5760)
