class_name SocialLifeValidation
extends RefCounted
## Bounded authoring contract, not a content-provided method dispatcher.
static func validate(bundle: Dictionary) -> ActionResult:
 var data: Variant=bundle.get("social_life")
 if not data is Dictionary:return ContentValidation.fail("social_life")
 for key in ["companionship","trial","relationships","actions","topics"]:
  if not data.get(key) is Dictionary:return ContentValidation.fail("social_life."+key)
 if data.trial.get("actors")!=["farid","youssef"]:return ContentValidation.fail("social_life.trial.actors")
 for field in ["appointment_minute","duration_minutes","reservation_lead_minutes"]:
  if not ContentValidation.bounded(data.trial.get(field),0,1440):return ContentValidation.fail("social_life.trial."+field)
 if data.trial.duration_minutes<=0:return ContentValidation.fail("social_life.trial.duration")
 for actor in data.trial.actors:
  if not bundle.get("visitors",{}).get("characters",{}).has(actor) or not data.trial.get("peer_gains",{}).get(actor) is Dictionary:return ContentValidation.fail("social_life.peer")
  for axis in ["familiarity","trust"]:
   if not ContentValidation.bounded(data.trial.peer_gains[actor].get(axis),0,100):return ContentValidation.fail("social_life.peer_gain")
 if not data.companionship.get("actors") is Array or not ContentValidation.bounded(data.companionship.get("radius"),0.1,3.4) or not ContentValidation.vector(data.companionship.get("wait_seconds"),2) or data.companionship.wait_seconds[0]<=0 or data.companionship.wait_seconds[0]>data.companionship.wait_seconds[1] or data.companionship.wait_seconds[1]>120 or not ContentValidation.bounded(data.companionship.get("choice_expiry"),0.1,120):return ContentValidation.fail("social_life.companionship")
 for actor in data.companionship.actors:
  if not actor in bundle.visitors.characters:return ContentValidation.fail("social_life.companion")
 if not ContentValidation.bounded(data.relationships.get("daily_cap"),1,100) or not data.relationships.get("stages") is Array or data.relationships.stages.is_empty():return ContentValidation.fail("social_life.relationships")
 var previous := -1.0
 for stage in data.relationships.stages:
  if not stage is Dictionary or not ContentValidation.bounded(stage.get("at"),0,100) or stage.at<=previous or not stage.get("label") is String:return ContentValidation.fail("social_life.stage")
  previous=stage.at
 for id in data.actions:
  var action: Variant=data.actions[id]
  if not id.is_valid_identifier() or not action is Dictionary or not action.get("actor") in bundle.visitors.characters.keys()+[""] or not action.get("needs") is Array or not action.get("facts") is Array or not action.get("phases") is Array or not action.get("note") is String or not action.get("moment") is String:return ContentValidation.fail("social_life.action."+id)
  for axis in ["familiarity","trust"]:
   if not ContentValidation.bounded(action.get(axis),0,100):return ContentValidation.fail("social_life.action.gain")
  if not action.get("learn") in bundle.social.facts+[""]:return ContentValidation.fail("social_life.action.learn")
  for fact in action.facts:
   if not fact in bundle.social.facts:return ContentValidation.fail("social_life.action.fact")
  for required in action.needs:
   if not required in data.actions or required==id:return ContentValidation.fail("social_life.action.dependency")
  for phase in action.phases:
   if not phase in ["idle","coordinating","scheduled","waiting","active","completed"]:return ContentValidation.fail("social_life.action.phase")
 for required in ["meet_farid","meet_youssef","hear_farid","hear_youssef","refer_farid","refer_youssef","consent_farid","consent_youssef","days_farid","days_youssef","trial_complete"]:
  if not data.actions.has(required):return ContentValidation.fail("social_life.required_action")
 for id in data.topics:
  var topic: Variant=data.topics[id]
  if not topic is Dictionary or not topic.get("actor") in data.companionship.actors or not topic.get("label") is String or not topic.get("action") in data.actions.keys()+[""] or not topic.get("encounter") is String or not bundle.get("encounters",{}).has(topic.encounter):return ContentValidation.fail("social_life.topic")
 return ActionResult.success()
