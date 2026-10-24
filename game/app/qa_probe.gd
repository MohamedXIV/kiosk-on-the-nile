class_name QaProbe
extends Node
var session: GameSession
var _elapsed: float = 0
func _process(delta: float) -> void:
 if not OS.is_debug_build() or not OS.has_feature("web"): return
 _elapsed += delta
 if _elapsed<0.25: return
 _elapsed = 0
 var snapshot := {"phase":"title"}
 if session:
  snapshot = {"phase":"playing","location":str(session.location_id),"clock":session.clock.snapshot(),"routine":session.routine.snapshot(),"wallet":session.wallet.snapshot(),"needs":session.needs.snapshot(),"accounts":session.accounts.snapshot(),"commitments":session.commitments.snapshot(),"residential":session.residential.snapshot(),"district":session.district.snapshot(),"tuning":session.tuning.snapshot(),"alertness":session.alertness.snapshot(),"actions":session.actions.snapshot(),"fatigue":session.fatigue.snapshot(),"cooking":session.cooking.snapshot(),"hygiene":session.hygiene.snapshot(),"customer_experience":session.customer_experience.snapshot(),"workflow":session.workflow.snapshot(),"travel":session.travel.snapshot(),"shops":session.shops.snapshot(),"items":session.items.snapshot(),"spaces":session.spaces.snapshot(),"held":session.cooking.held_item().snapshot() if session.cooking.held_item() else null,"visitors":session.visitors.snapshot(),"narrative":session.narrative.snapshot(),"pose":session.player_pose.snapshot(),"simulation_order":session.coordinator.order,"system_failures":session.coordinator.last_failures,"journal":session.journal.snapshot(),"personal":session.personal.snapshot(),"inner":session.inner.snapshot(),"social_life":session.social_life.snapshot(),"knowledge":session.knowledge.snapshot(),"relationships":session.relationships.snapshot(),"scheduler":session.scheduler.snapshot()}
 # A serialized observation only. There is no callable bridge into game services.
 JavaScriptBridge.eval("window.gameStatus=Object.freeze("+JSON.stringify(snapshot)+")")
