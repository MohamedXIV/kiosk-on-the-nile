class_name CharacterLife
extends RefCounted
## Actor state and coarse decisions. Reading projections never consumes RNG or mutates state.
var environment_provider: Callable
var menu: MenuService
var _data: Dictionary
var _foods: FoodRegistry
var _clock: GameClock
var _states: Dictionary={}
var _satisfied: Dictionary={}
var _rng := RandomNumberGenerator.new()
func configure(data: Dictionary, foods: FoodRegistry, clock: GameClock) -> ActionResult:
 if not data.get("profiles") is Dictionary:return _invalid("character_life_profiles")
 var definitions := {}
 for id in foods.ids():definitions[id]=foods.definition(StringName(id))
 var result := CharacterLifeValidation.validate(data,data.get("profiles",{}).keys(),definitions)
 if not result.ok:return result
 _data=data.duplicate(true);_foods=foods;_clock=clock
 _states.clear();_satisfied.clear()
 if int(data.policy.seed)==0:_rng.randomize()
 else:_rng.seed=int(data.policy.seed)
 return ActionResult.success()
func profile(actor: StringName) -> Dictionary:
 return _data.profiles.get(str(actor),{}).duplicate(true)
func state(actor: StringName) -> Dictionary:
 return _project(str(actor)) if _states.has(str(actor)) else {}
func ensure(actor: StringName) -> ActionResult:
 var p := profile(actor)
 if p.is_empty():return _invalid("character_life_actor")
 if not _states.has(str(actor)):
  var needs := {}
  for need in CharacterLifeValidation.NEEDS:needs[need]=_rng.randf_range(float(p.initial[need][0]),float(p.initial[need][1]))
  _states[str(actor)]={"needs":needs,"at":_clock.world_minutes,"visit":"","decisions":0,"decision":{}}
 return ActionResult.success()
func arrive(actor: StringName, visit: StringName) -> ActionResult:
 if not _visit_id(str(visit)):return _invalid("character_life_visit")
 var initialised := ensure(actor)
 if not initialised.ok:return initialised
 var current := _project(str(actor))
 if current.visit!=str(visit):
  current.visit=str(visit);current.decisions=0;current.decision={}
 _states[str(actor)]=current
 return ActionResult.success()
func consider(actor: StringName, visit: StringName, offers: Array[Dictionary], expected: Dictionary={}) -> Dictionary:
 var current := state(actor)
 if not _visit_id(str(visit)) or current.is_empty() or current.visit!=str(visit):return {"intent":"quiet","food_id":"","reason":"actor_unavailable"}
 var previous: Dictionary=current.decision
 if not previous.is_empty() and _clock.world_minutes<float(previous.next_at):
  if not str(previous.food_id).is_empty():
   var current_offer := offers.any(func(o):return o.get("variant_id")==previous.get("variant_id") and o.get("additions")==previous.get("additions") and o.get("price_minor")==previous.get("price_minor"))
   if not current_offer:
    previous=previous.duplicate(true);previous.food_id="";previous.intent="quiet";previous.variant_id="";previous.additions=[];previous.price_minor=-1;previous.factors={"quiet":1.0}
    current.decision=previous;_states[str(actor)]=current
  return previous.duplicate(true)
 var p := profile(actor)
 var needs: Dictionary=current.needs
 var quiet := float(_data.policy.quiet_weight)*(0.4+0.7*(1.0-maxf(float(needs.hunger),float(needs.thirst)))+float(needs.tiredness)*0.5)
 var candidates: Array[Dictionary]=[]
 var total := quiet
 var seen := {};var counts := {}
 for offer in offers:
  if ContentValidation.integer(offer.get("price_minor")) and int(offer.price_minor)<=int(p.spend_limit_minor) and _foods.has_food(StringName(str(offer.get("food_id","")))) and ContentValidation.bounded(offer.get("spice"),0,float(p.spice_limit)):
   counts[str(offer.food_id)]=int(counts.get(str(offer.food_id),0))+1
 if p.buying_enabled:
  for offer in offers:
   var food := str(offer.get("food_id",""))
   var key := str(offer.get("variant_id",""))+StableJson.stringify(offer.get("additions",[]))
   if seen.has(key) or not offer.get("variant_id") is String or not offer.get("additions") is Array or not _foods.has_food(StringName(food)) or not ContentValidation.integer(offer.get("price_minor")) or offer.price_minor<0 or int(offer.price_minor)>int(p.spend_limit_minor):continue
   seen[key]=true
   var d := _foods.definition(StringName(food))
   if not ContentValidation.bounded(offer.get("spice"),0,float(p.spice_limit)):continue
   d.spice=float(offer.spice)
   var known: Variant=expected.get(food,{})
   if not known is Dictionary or (known.has("score") and not ContentValidation.bounded(known.score,0,100)):continue
   var factors := _factors(p,needs,d,food,int(offer.price_minor),known)
   var weight: float=factors.need*factors.preference*factors.price*factors.memory/maxi(1,int(counts.get(food,1)))
   if weight<=0:continue
   candidates.append({"food_id":food,"variant_id":offer.variant_id,"additions":offer.additions.duplicate(),"price_minor":int(offer.price_minor),"weight":weight,"factors":factors});total+=weight
 var choice := {"variant_id":"","additions":[],"price_minor":-1,"food_id":"","intent":"rest" if float(needs.tiredness)>0.8 else "company" if float(needs.social)>0.6 else "quiet","factors":{"quiet":quiet}}
 var roll := _rng.randf()*total
 if roll>=quiet:
  roll-=quiet
  for candidate in candidates:
   roll-=float(candidate.weight)
   if roll<=0:
    choice={"variant_id":candidate.variant_id,"additions":candidate.additions.duplicate(),"price_minor":candidate.price_minor,"food_id":candidate.food_id,"intent":"drink" if _foods.definition(StringName(candidate.food_id)).category=="drink" else "eat","factors":candidate.factors};break
 current.decisions=int(current.decisions)+1
 choice["visit"]=str(visit);choice["index"]=current.decisions;choice["at"]=_clock.world_minutes
 choice["next_at"]=_clock.world_minutes+float(_data.policy.reconsider_minutes)
 current.decision=choice;_states[str(actor)]=current
 return choice.duplicate(true)
func _factors(p: Dictionary, needs: Dictionary, food: Dictionary, id: String, price: int, memory: Dictionary) -> Dictionary:
 var maximum := 1.0
 for weight in p.food_weights.values():maximum=maxf(maximum,float(weight))
 var preference := float(p.food_weights.get(id,maximum*0.35))/maximum
 preference*=float(p.category_weights[food.category])*float(p.temperature_weights[food.temperature])
 var spice_mid := (float(p.spice_preference[0])+float(p.spice_preference[1]))*0.5
 preference*=clampf(1.0-absf(float(food.spice)-spice_mid)*0.65,0.2,1.0)
 if _clock.minutes<float(p.preferred_window[0]) or _clock.minutes>=float(p.preferred_window[1]):preference*=0.8
 var need := 0.1+(float(needs.thirst)*2.2 if food.category=="drink" else float(needs.hunger)*1.8)
 # Only remembered, experienced scores enter here. Actual untried lot quality does not.
 var known := 1.0
 if ContentValidation.bounded(memory.get("score"),0,100):known=0.5+float(memory.score)/100.0
 var reference := maxi(1,int(food.price_minor))
 var value := clampf(pow(float(reference)/maxf(1.0,float(price)),float(p.price_sensitivity)),0.03,2.0)
 return {"need":need,"preference":preference,"price":value,"memory":known}
func satisfy(actor: StringName, source: String, food: StringName, at: float) -> ActionResult:
 if not _states.has(str(actor)) or not _foods.has_food(food) or source.is_empty() or not ContentValidation.bounded(at,0,_clock.world_minutes):return _invalid("character_life_satisfaction")
 var receipt := {"actor":str(actor),"food_id":str(food),"at":at}
 if _satisfied.has(source):return ActionResult.success({"duplicate":true}) if _satisfied[source]==receipt else _invalid("character_life_satisfaction_source")
 # Sources must be committed at their actual current-time boundary; no retroactive feeding.
 if absf(at-_clock.world_minutes)>0.001:return _invalid("character_life_satisfaction_time")
 var current := state(actor)
 var d := _foods.definition(food)
 current.needs.hunger=maxf(0,float(current.needs.hunger)-float(d.satiation))
 current.needs.thirst=maxf(0,float(current.needs.thirst)-float(d.hydration))
 _states[str(actor)]=current;_satisfied[source]=receipt
 return ActionResult.success()
func _project(actor: String) -> Dictionary:
 var current: Dictionary=_states[actor].duplicate(true)
 var elapsed := clampf(_clock.world_minutes-float(current.at),0,float(_data.policy.elapsed_cap_minutes))/60.0
 for need in CharacterLifeValidation.NEEDS:
  current.needs[need]=clampf(float(current.needs[need])+elapsed*float(_data.policy.rates[need]),0,1)
 # A coarse overnight/rest assumption for long gaps, not an off-screen life simulation.
 if floori(_clock.world_minutes/1440.0)>floori(float(current.at)/1440.0) and _clock.world_minutes-float(current.at)>=240:
  current.needs.tiredness=maxf(0,float(current.needs.tiredness)-0.5)
 current.at=_clock.world_minutes
 return current
func snapshot() -> Dictionary:
 return {"actors":_states.duplicate(true),"satisfied":_satisfied.duplicate(true),"rng_state":str(_rng.state)}
func restore(data: Dictionary) -> ActionResult:
 if not CharacterLifeValidation.keys(data,["actors","satisfied","rng_state"]) or not data.actors is Dictionary or not data.satisfied is Dictionary or not data.rng_state is String or not data.rng_state.is_valid_int():return _invalid("character_life_state")
 for actor in data.actors:
  var record: Variant=data.actors[actor]
  if not _data.profiles.has(actor) or not record is Dictionary or not CharacterLifeValidation.keys(record,["needs","at","visit","decisions","decision"]) or not record.needs is Dictionary or not CharacterLifeValidation.keys(record.needs,CharacterLifeValidation.NEEDS):return _invalid("character_life_actor")
  for value in record.needs.values():
   if not ContentValidation.bounded(value,0,1):return _invalid("character_life_needs")
  if not ContentValidation.bounded(record.at,0,_clock.world_minutes) or not record.visit is String or (not record.visit.is_empty() and not _visit_id(record.visit)) or not ContentValidation.integer(record.decisions) or record.decisions<0 or not record.decision is Dictionary:return _invalid("character_life_time")
  var decision: Dictionary=record.decision
  if decision.is_empty():
   if record.decisions!=0:return _invalid("character_life_decision")
   continue
  if not CharacterLifeValidation.keys(decision,["food_id","intent","factors","visit","index","at","next_at","variant_id","additions","price_minor"]) or decision.visit!=record.visit or decision.index!=record.decisions or not decision.intent in ["quiet","company","rest","eat","drink"] or not decision.food_id is String or not decision.factors is Dictionary:return _invalid("character_life_decision")
  if not decision.get("variant_id") is String or not decision.get("additions") is Array or not ContentValidation.integer(decision.get("price_minor")):return _invalid("character_life_offer")
  if record.visit.is_empty():return _invalid("character_life_decision_visit")
  var buying: bool=decision.intent in ["eat","drink"]
  if buying!=(not decision.food_id.is_empty()) or (buying and not _foods.has_food(StringName(decision.food_id))) or not ContentValidation.bounded(decision.at,0,float(record.at)) or not ContentValidation.number(decision.next_at) or absf(float(decision.next_at)-float(decision.at)-float(_data.policy.reconsider_minutes))>0.001:return _invalid("character_life_choice")
  if not ContentValidation.integer(decision.index) or decision.index<1:return _invalid("character_life_index")
  if not buying and (decision.variant_id!="" or not decision.additions.is_empty() or decision.price_minor!= -1):return _invalid("character_life_offer")
  if buying:
   if menu==null or not menu.plan(StringName(decision.food_id),{"variant_id":decision.variant_id,"additions":decision.additions}).ok or not ContentValidation.bounded(decision.price_minor,0,float(_data.profiles[actor].spend_limit_minor)):return _invalid("character_life_offer")
   var food := _foods.definition(StringName(decision.food_id))
   var spice := float(food.spice)
   for addition in decision.additions:spice+=float(menu._data.additions[addition].spice)
   if (food.category=="drink")!=(decision.intent=="drink") or not _data.profiles[actor].buying_enabled or clampf(spice,0,1)>float(_data.profiles[actor].spice_limit):return _invalid("character_life_intent")
  if not CharacterLifeValidation.keys(decision.factors,["need","preference","price","memory"] if buying else ["quiet"]):return _invalid("character_life_factors")
  for weight in decision.factors.values():
   if not ContentValidation.bounded(weight,0,100):return _invalid("character_life_factors")
 for source in data.satisfied:
  var receipt: Variant=data.satisfied[source]
  if not source is String or source.is_empty() or not receipt is Dictionary or not CharacterLifeValidation.keys(receipt,["actor","food_id","at"]) or not data.actors.has(receipt.actor) or not _foods.has_food(StringName(str(receipt.food_id))) or not ContentValidation.bounded(receipt.at,0,_clock.world_minutes):return _invalid("character_life_satisfaction")
 _states=data.actors.duplicate(true);_satisfied=data.satisfied.duplicate(true);_rng.state=int(data.rng_state)
 return ActionResult.success()
func validate_visits(visitors: VisitorService) -> ActionResult:
 var next := int(visitors.snapshot().next_id)
 for record in _states.values():
  if not str(record.visit).is_empty() and int(str(record.visit).trim_prefix("visit_"))>=next:return _invalid("character_life_visit")
 for visit in visitors.visits.values():
  if not _states.has(str(visit.character_id)) or _states[str(visit.character_id)].visit!=str(visit.id):return _invalid("character_life_visit")
 return ActionResult.success()
static func _visit_id(value: String) -> bool:
 var suffix := value.trim_prefix("visit_")
 return value.begins_with("visit_") and suffix.is_valid_int() and int(suffix)>0 and str(int(suffix))==suffix
static func _invalid(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(reason))

func intent_for(actor: StringName, visit: StringName) -> StringName:
 # Narrow owned decision view: no projection copy and no RNG on a frame read.
 var record: Dictionary=_states.get(str(actor),{})
 return StringName(str(record.get("decision",{}).get("intent","quiet"))) if record.get("visit")==str(visit) else &"quiet"
func stay_factor(actor: StringName, visit: StringName) -> float:
 var intent := intent_for(actor,visit)
 return float(_data.policy.company_stay_multiplier) if intent==&"company" else float(_data.policy.rest_stay_multiplier) if intent==&"rest" else 1.0
func company_rate(actor: StringName, visit: StringName) -> float:
 return float(_data.policy.company_invite_rate) if intent_for(actor,visit)==&"company" else 1.0
