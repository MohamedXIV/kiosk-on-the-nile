class_name StoryMessageValidation
extends RefCounted
## Optional authored story gates and explicit message lineage on the social ledger.
static func validate(data: Dictionary, actors: Dictionary) -> ActionResult:
 for id in data.actions:
  var action: Dictionary=data.actions[id]
  if not action.get("next_day_after",[]) is Array or not action.get("absent_actor","") in actors.keys()+[""]:return ContentValidation.fail("social_life.story_gate")
  for previous in action.get("next_day_after",[]):
   if not previous in action.needs:return ContentValidation.fail("social_life.story_day_dependency")
  if not action.has("message"):continue
  var message: Variant=action.message
  if not message is Dictionary or message.size()!=4 or not message.get("kind") in ["request","reply","delivered"] or not message.get("from") in actors or not message.get("to") in actors or message.from==message.to or not message.get("previous") is String:return ContentValidation.fail("social_life.message")
  if message.kind=="request":
   if message.from!=action.actor or message.previous!="" or action.get("absent_actor")!=message.to:return ContentValidation.fail("social_life.message_request")
  else:
   if not message.previous in action.needs or not data.actions[message.previous].get("message") is Dictionary:return ContentValidation.fail("social_life.message_dependency")
   var previous: Dictionary=data.actions[message.previous].message
   if message.kind=="reply":
    if previous.kind!="request" or message.from!=previous.to or message.to!=previous.from or action.actor!=message.from:return ContentValidation.fail("social_life.message_reply")
   elif previous.kind!="reply" or message.from!=previous.from or message.to!=previous.to or action.actor!=message.to:return ContentValidation.fail("social_life.message_delivery")
 # Reject cycles in authored action prerequisites without recursion on untrusted data.
 var remaining: Array=data.actions.keys()
 var resolved: Array=data.get("semantic_introductions",{}).keys()
 while not remaining.is_empty():
  var progress := false
  for id in remaining.duplicate():
   var ready := true
   for required in data.actions[id].needs:
    if not required in resolved:ready=false
   if ready:remaining.erase(id);resolved.append(id);progress=true
  if not progress:return ContentValidation.fail("social_life.action_cycle")
 return ActionResult.success()
