class_name NarrativeLocalization
extends RefCounted
## Captured presentation arguments only; never prepares quotes or advances Ink.
static func date(at: float) -> Dictionary:
 var minute := int(fposmod(at,1440))
 return {"text_ref":"narrative.date","parameters":{"day":floori(at/1440)+1,"hour":"%02d" % (minute/60),"minute":"%02d" % (minute%60)}}
static func capture(session: GameSession, context: Dictionary) -> Dictionary:
 var args: Dictionary={}
 for key in context:
  if context[key] is String or context[key] is int or context[key] is float or context[key] is bool:args[key]=context[key]
 args.merge(context.get("localization_args",{}),true)
 for key in ["order_label","venue_previous_food"]:
  var source := str(context.get(key,""))
  for id in session.config.section("foods"):
   var food := session.foods.definition(StringName(id))
   if food.get("menu_label")==source:
    args[key]=LocaleService.current.captured_reference("food."+str(id)+".menu",source) if LocaleService.current else source;break
 return args
