class_name SupplyService
extends RefCounted
var _wallet: WalletService
var _cooking: CookingService
var _home: HomeService
var _knowledge: KnowledgeBook
var _balance: Dictionary
func _init(wallet: WalletService, cooking: CookingService, home: HomeService, knowledge: KnowledgeBook, balance: Dictionary) -> void:
 _wallet = wallet
 _cooking = cooking
 _home = home
 _knowledge = knowledge
 _balance = balance.duplicate(true)
func buy_stock() -> ActionResult:
 var paid := _wallet.try_spend(int(_balance.supply_price))
 if not paid.ok: return paid
 _cooking.restock(int(_balance.supply_tea),int(_balance.supply_kebda))
 return ActionResult.success({"cue":"coin"})
func buy_fan() -> ActionResult:
 if not _knowledge.has(&"KNOWN_CHEAP_FAN"): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"fan_unknown")
 if _home.has_fan: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"already_owned")
 var paid := _wallet.try_spend(int(_balance.fan_price))
 if not paid.ok: return paid
 _home.install_fan()
 _knowledge.learn(&"BOUGHT_FAN","", "purchase")
 return ActionResult.success({"cue":"coin"})
