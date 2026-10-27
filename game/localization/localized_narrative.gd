class_name LocalizedNarrative
extends RefCounted
## Read-only presentation. No call to Ink.advance, quote preparation or gameplay effects.
static func line(frame: NarrativeTypes.Frame) -> String:
 return resolve(frame.loc_id,frame.loc_args,frame.text)
static func choice(value: Dictionary, frame: NarrativeTypes.Frame) -> String:
 return resolve(str(value.get("loc_id","")),frame.loc_args,str(value.text))
static func resolve(id: String, args: Dictionary, fallback: String) -> String:
 return LocaleService.current.text(id,args,fallback) if id!="" and LocaleService.current!=null else fallback
static func speaker(actor: String, source_name: String) -> String:
 return LocaleService.current.source_text("actor."+actor,source_name) if LocaleService.current else source_name
static func metadata(id: String, args: Dictionary, canonical: String) -> Dictionary:
 if id=="" or LocaleService.current==null:return {}
 return {"text_ref":id,"parameters":args.duplicate(true),"canonical_text":canonical,"locale":LocaleService.current.locale}
