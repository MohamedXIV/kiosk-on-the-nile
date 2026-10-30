class_name CharacterLife
extends RefCounted
## Actor state and coarse decisions. Reading projections never consumes RNG or mutates state.
var environment_provider: Callable
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
func arrive(actor: StringName, visit: StringName) -> ActionResult:
 var p := profile(actor)
 if p.is_empty() or not _visit_id(str(visit)):return _invalid("character_life_actor")
 if not _states.has(str(actor)):
  var needs := {}
  for need in CharacterLifeValidation.NEEDS:needs[need]=_rng.randf_range(float(p.initial[need][0]),float(p.initial[need][1]))
  _states[str(actor)]={"needs":needs,"at":_clock.world_minutes,"visit":"","decisions":0,"decision":{}}
 var current := _project(str(actor))
 if current.visit!=str(visit):
  current.visit=str(visit);current.decisions=0;current.decision={}
 _states[str(actor)]=current
 return ActionResult.success()
func consider(actor: StringName, visit: StringName, offers: Array[Dictionary], expected: Dictionary={}) -> Dictionary:
 var current := state(actor)
 if current.is_empty() or current.visit!=str(visit):return {"intent":"quiet","food_id":"","reason":"actor_unavailable"}
 var previous: Dictionary=current.decision
 if not previous.is_empty() and _clock.world_minutes<float(previous.next_at):return previous.duplicate(true)
 var p := profile(actor)
 var needs: Dictionary=current.needs
 var quiet := float(_data.policy.quiet_weight)*(0.4+0.7*(1.0-maxf(float(needs.hunger),float(needs.thirst)))+float(needs.tiredness)*0.5)
 var candidates: Array[Dictionary]=[]
 var total := quiet
 var seen := {}
 if p.buying_enabled:
  for offer in offers:
   var food := str(offer.get("food_id",""))
   if seen.has(food) or not _foods.has_food(StringName(food)) or not ContentValidation.integer(offer.get("price_minor")) or offer.price_minor<0:continue
   seen[food]=true
   var d := _foods.definition(StringName(food))
   if float(d.spice)>float(p.spice_limit):continue
   var known: Variant=expected.get(food,{})
   if not known is Dictionary or (known.has("score") and not ContentValidation.bounded(known.score,0,100)):continue
   var factors := _factors(p,needs,d,food,int(offer.price_minor),known)
   var weight: float=factors.need*factors.preference*factors.price*factors.memory
   if weight<=0:continue
   candidates.append({"food_id":food,"weight":weight,"factors":factors});total+=weight
 var choice := {"food_id":"","intent":"rest" if float(needs.tiredness)>0.8 else "company" if float(needs.social)>0.6 else "quiet","factors":{"quiet":quiet}}
 var roll := _rng.randf()*total
 if roll>=quiet:
  roll-=quiet
  for candidate in candidates:
   roll-=float(candidate.weight)
   if roll<=0:
    choice={"food_id":candidate.food_id,"intent":"drink" if _foods.definition(StringName(candidate.food_id)).category=="drink" else "eat","factors":candidate.factors};break
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
  if not ContentValidation.bounded(record.at,0,_clock.world_minutes) or not _visit_id(str(record.visit)) or not ContentValidation.integer(record.decisions) or record.decisions<0 or not record.decision is Dictionary:return _invalid("character_life_time")
  var decision: Dictionary=record.decision
  if decision.is_empty():
   if record.decisions!=0:return _invalid("character_life_decision")
   continue
  if not CharacterLifeValidation.keys(decision,["food_id","intent","factors","visit","index","at","next_at"]) or decision.visit!=record.visit or decision.index!=record.decisions or not decision.intent in ["quiet","company","rest","eat","drink"] or not decision.food_id is String or not decision.factors is Dictionary:return _invalid("character_life_decision")
  var buying: bool=decision.intent in ["eat","drink"]
  if buying!=(not decision.food_id.is_empty()) or (buying and not _foods.has_food(StringName(decision.food_id))) or not ContentValidation.bounded(decision.at,0,float(record.at)) or not ContentValidation.number(decision.next_at) or absf(float(decision.next_at)-float(decision.at)-float(_data.policy.reconsider_minutes))>0.001:return _invalid("character_life_choice")
  if not ContentValidation.integer(decision.index) or decision.index<1:return _invalid("character_life_index")
  if buying:
   var food := _foods.definition(StringName(decision.food_id))
   if (food.category=="drink")!=(decision.intent=="drink") or not _data.profiles[actor].buying_enabled or float(food.spice)>float(_data.profiles[actor].spice_limit):return _invalid("character_life_intent")
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
  if int(str(record.visit).trim_prefix("visit_"))>=next:return _invalid("character_life_visit")
 for visit in visitors.visits.values():
  if not _states.has(str(visit.character_id)) or _states[str(visit.character_id)].visit!=str(visit.id):return _invalid("character_life_visit")
 return ActionResult.success()
static func _visit_id(value: String) -> bool:
 var suffix := value.trim_prefix("visit_")
 return value.begins_with("visit_") and suffix.is_valid_int() and int(suffix)>0 and str(int(suffix))==suffix
static func _invalid(reason: String) -> ActionResult:
 return ActionResult.failure(ActionResult.Code.INVALID_SAVE,StringName(reason))
