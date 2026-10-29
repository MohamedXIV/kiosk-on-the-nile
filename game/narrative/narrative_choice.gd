class_name NarrativeChoice
extends RefCounted
## Actual manual input, independent of the NPC's subsequent confirmation.
static func capture(session: GameSession, c: ConversationSession, choice: Dictionary) -> ActionResult:
 var proof: Dictionary={"id":"%s/%d/choice" % [c.id,c.beat],"episode":str(c.id),"beat":c.beat,"choice":str(choice.get("semantic_id","")),"encounter":str(c.encounter_id),"story_hash":c.runtime._definition.sha256,"at":session.clock.world_minutes,"frame":c.current.to_dict()}
 if proof.choice.is_empty():return _fail()
 var event: Dictionary={"id":proof.id,"chapter":str(c.id),"actor":"player","name":LocalizedNarrative.speaker("player",str(session.config.section("ui").get("player_name","أنا"))),"text":LocalizedNarrative.choice(choice,c.current),"channel":"choice","at":session.clock.world_minutes,"semantic_choice":proof.duplicate(true)}
 event.merge(LocalizedNarrative.metadata(str(choice.get("loc_id","")),c.current.loc_args,str(choice.text)))
 var result:=session.journal.append_once(event)
 if result.ok:c.context_extra["semantic_choice"]=proof
 return result
static func valid(session: GameSession, proof: Variant, episode: String, beat: int, encounter: String, choice: String, at: float) -> bool:
 if not NarrativePolicyValidation.fields(proof,["id","episode","beat","choice","encounter","story_hash","at","frame"]) or not ContentValidation.integer(proof.beat) or proof.beat<1 or proof.episode!=episode or int(proof.beat)+1!=beat or proof.choice!=choice or proof.encounter!=encounter or proof.id!="%s/%d/choice" % [episode,int(proof.beat)] or not ContentValidation.bounded(proof.at,0,at) or not proof.frame is Dictionary or not proof.frame.get("choices") is Array:return false
 var entry: Dictionary=session.config.data.encounters.get(encounter,{})
 var story: Variant=session.narrative._stories.get(entry.get("story",""))
 if story==null or proof.story_hash!=story.sha256:return false
 var event:=session.journal.event(proof.id)
 if event.get("chapter")!=episode or event.get("actor")!="player" or event.get("channel")!="choice" or event.get("at")!=proof.at or not NarrativePolicyValidation.equivalent(event.get("semantic_choice"),proof):return false
 var matches: Array=proof.frame.choices.filter(func(c):return c is Dictionary and c.get("semantic_id")==choice)
 if matches.size()!=1 or str(matches[0].get("text","")).is_empty():return false
 var mapped:=InkChoiceMap.compile(JSON.parse_string(story.raw_json))
 return mapped.ok and mapped.details.choices.get(str(matches[0].get("semantic_path","")))==choice
static func _fail() -> ActionResult:return ActionResult.failure(ActionResult.Code.INVALID_CHOICE,&"invalid_semantic_choice_evidence")
