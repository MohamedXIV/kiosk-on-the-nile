class_name SupplyService
extends RefCounted
var _wallet: WalletService
var _cooking: CookingService
var _home: HomeService
var _knowledge: KnowledgeBook
var _items: ItemStore
var _balance: Dictionary
func _init(wallet: WalletService, cooking: CookingService, home: HomeService, knowledge: KnowledgeBook, balance: Dictionary, items: ItemStore) -> void:
 _items = items
 _wallet = wallet
 _cooking = cooking
 _home = home
 _knowledge = knowledge
 _balance = balance.duplicate(true)
func buy_stock() -> ActionResult:
 var grants: Array[Dictionary] = []
 for entry in [{"definition_id":"tea_portion","quantity":int(_balance.supply_tea)},{"definition_id":"kebda_portion","quantity":int(_balance.supply_kebda)}]:
  grants.append({"definition_id":entry.definition_id,"quantity":entry.quantity,"container_id":"kiosk_dry","attributes":{}})
 var candidate := _items.prepare_grants(grants)
 if not candidate.ok: return candidate
 var paid := _wallet.try_spend(int(_balance.supply_price))
 if not paid.ok: return paid
 var committed := _items.commit(candidate.details.change)
 if not committed.ok:
  _wallet.credit(int(_balance.supply_price))
  return committed
 return ActionResult.success({"cue":"coin"})
func buy_fan() -> ActionResult:
 if not _knowledge.has(&"KNOWN_CHEAP_FAN"): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"fan_unknown")
 if _home.has_fan: return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"already_owned")
 var paid := _wallet.try_spend(int(_balance.fan_price))
 if not paid.ok: return paid
 var installed := _home.install_fan()
 if not installed.ok:
  _wallet.credit(int(_balance.fan_price))
  return installed
 _knowledge.learn(&"BOUGHT_FAN","", "purchase")
 return ActionResult.success({"cue":"coin"})
