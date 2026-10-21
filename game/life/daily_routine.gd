class_name DailyRoutine
extends RefCounted
signal slept
var clock: GameClock
var wallet: WalletService
var needs: NeedsService
var home: HomeService
var rent: int
func _init(source_clock: GameClock, source_wallet: WalletService, source_needs: NeedsService, source_home: HomeService, daily_rent: int) -> void:
 clock = source_clock
 wallet = source_wallet
 needs = source_needs
 home = source_home
 rent = daily_rent
func sleep() -> ActionResult:
 var paid := false
 if wallet.balance >= rent:
  wallet.try_spend(rent)
  paid = true
 clock.next_day()
 needs.after_sleep(home.has_fan and home.fan_on)
 slept.emit()
 return ActionResult.success({"rent_paid":paid})
