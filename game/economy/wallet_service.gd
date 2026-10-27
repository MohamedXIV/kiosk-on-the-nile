class_name WalletService
extends RefCounted
var balance: int
func _init(initial: int = 0) -> void:
 balance = initial
func try_spend(amount: int) -> ActionResult:
 if amount < 0: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_amount")
 if amount > balance: return ActionResult.failure(ActionResult.Code.INSUFFICIENT_FUNDS,&"insufficient_funds")
 balance -= amount
 return ActionResult.success({"amount":-amount})
func credit(amount: int) -> ActionResult:
 if amount < 0: return ActionResult.failure(ActionResult.Code.INVALID_CONTENT,&"invalid_amount")
 balance += amount
 return ActionResult.success({"amount":amount})
func snapshot() -> Dictionary:
 return {"balance":balance}
func restore(data: Dictionary) -> ActionResult:
 var value: Variant = data.get("balance")
 if not typeof(value) in [TYPE_INT,TYPE_FLOAT] or float(value) < 0 or not is_finite(float(value)) or float(value) != floor(float(value)):
  return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_wallet")
 balance = int(value)
 return ActionResult.success()
