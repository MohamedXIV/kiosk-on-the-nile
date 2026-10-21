class_name GameSession
extends Node
signal changed
var config: SessionConfig
var clock: GameClock
var wallet: WalletService
var needs: NeedsService
var home: HomeService
var knowledge: KnowledgeBook
var routine: DailyRoutine
var coordinator := SimulationCoordinator.new()
var scheduler := WorldScheduler.new()
var running: bool = false
var location_id: StringName = &"rooftop"
var kiosk_open: bool = false
var player_ground := Vector2(0,0.5)
var last_result := ActionResult.success()
func configure(source: SessionConfig) -> ActionResult:
 for key in ["time","balance","needs","social"]:
  if not source.data.get(key) is Dictionary: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"missing_section",{"section":key})
 var validation := ContentValidation.validate(source.data)
 if not validation.ok: return validation
 config = source
 var balance: Dictionary = source.section("balance")
 if not typeof(balance.get("starting_money")) in [TYPE_INT,TYPE_FLOAT] or balance.starting_money < 0:
  return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_starting_money")
 clock = GameClock.new(source.section("time"))
 wallet = WalletService.new(int(balance.starting_money))
 needs = NeedsService.new(source.section("needs"))
 home = HomeService.new()
 knowledge = KnowledgeBook.new(source.section("social"))
 routine = DailyRoutine.new(clock,wallet,needs,home,int(balance.daily_rent))
 scheduler.configure({})
 return rebuild_order()
func rebuild_order() -> ActionResult:
 var handlers := {"needs":func(frame):needs.tick(frame.delta,kiosk_open),"scheduler":func(frame):scheduler.tick(frame)}
 return coordinator.prepare(clock,handlers,config.section("time").system_dependencies)
func start_new() -> void:
 running = true
func tick(delta: float) -> void:
 if not running: return
 last_result = coordinator.step(delta)
 changed.emit()
