class_name Diagnostics
extends Node
## Disposable in-memory owners. Never reads or writes the player's save store.
func inspect(config: SessionConfig) -> ActionResult:
 var validation := ContentValidation.validate(config.data)
 if not validation.ok: return validation
 var fixture := GameSession.new()
 add_child(fixture)
 var result := fixture.configure(config)
 if result.ok:
  var before := fixture.wallet.balance
  fixture.wallet.try_spend(before+1)
  if fixture.wallet.balance!=before: result=ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"diagnostic_wallet_failed")
 if result.ok:
  var story := StoryDefinition.new()
  story.id = &"diagnostic"
  story.raw_json = JSON.stringify(config.section("story_amgad"),"",true)
  story.sha256 = story.raw_json.sha256_text()
  var runtime := InkRuntime.new()
  fixture.add_child(runtime)
  result = await runtime.open(story,{"day":1,"mode":1,"amgad_visits":1})
  if result.ok: result = runtime.advance().result
  runtime.close()
 fixture.queue_free()
 return result
