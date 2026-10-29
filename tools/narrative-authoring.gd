extends SceneTree
## Offline developer CLI; never loaded by gameplay scenes.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args();var options: Dictionary={}
 var i:=0
 while i<args.size():
  if not args[i] in ["--content","--save","--encounter","--participants","--stage","--key"] or i+1>=args.size():
   print(JSON.stringify({"error":"Usage: --content DIR [--save FILE --encounter ID --participants visit1,visit2 --stage start|offer|continuation|choice|action --key ID]"}));quit(2);return
  options[args[i]]=args[i+1];i+=2
 var store:=ContentStore.new();root.add_child(store);store.required_sections=SessionConfig.REQUIRED_SECTIONS.duplicate()
 var directory: String=str(options.get("--content","res://content"))
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("manifest.json")))
 var manifest: Dictionary=parsed if parsed is Dictionary else {}
 var loaded:=store.load_directory(directory)
 if not loaded.ok:
  print(JSON.stringify(NarrativeDiagnostics.load_error(loaded,manifest,directory)));quit(1);return
 var report:=NarrativeDiagnostics.manifest_paths(NarrativeDiagnostics.inspect(store.bundle()),manifest,directory)
 if options.has("--encounter") and report.errors.is_empty():
  var config:=SessionConfig.new(store.bundle(),store.fingerprint,directory)
  var session: GameSession
  if options.has("--save"):
   var decoded:=SaveCodec.decode_text(FileAccess.get_file_as_string(str(options["--save"])))
   if not decoded.ok:print(JSON.stringify({"error":str(decoded.message_key)}));quit(1);return
   var codec:=SaveCodec.new();root.add_child(codec)
   var restored:=await codec.create_candidate(decoded.details.data,config)
   if not restored.ok:print(JSON.stringify({"error":str(restored.message_key),"details":restored.details}));quit(1);return
   session=restored.details.session
  else:
   session=GameSession.new();root.add_child(session)
   var configured:=session.configure(config)
   if not configured.ok:print(JSON.stringify({"error":str(configured.message_key)}));quit(1);return
   session.start_new()
  var id: String=str(options["--encounter"])
  var entry: Dictionary=config.data.encounters.get(id,{})
  if not entry.has("semantic_topic"):report.errors.append({"reason":"unknown_semantic_encounter","encounter":id})
  else:
   var participants: PackedStringArray=str(options.get("--participants","")).split(",",false)
   var bound:=session.semantic._context(entry,participants)
   if not bound.ok:report["decision"]=PolicyDecision.make("invalid","invalid_policy_bindings").snapshot()
   else:
    var context: NarrativeContext=bound.details.context
    var stage: String=str(options.get("--stage","offer"));var key: String=str(options.get("--key",""))
    var normal:=session.semantic.policy.evaluate(context,stage,key)
    var explained:=session.semantic.policy.evaluate(context,stage,key,true)
    report["decision"]=explained.snapshot()
    report["parity"]=normal.status==explained.status and normal.reasons==explained.reasons
    report["scope"]="Pure policy decision; physical lifecycle/domain transaction may separately reject an action."
  session.queue_free()
 print(JSON.stringify(report,"  "))
 quit(0 if report.errors.is_empty() else 1)
