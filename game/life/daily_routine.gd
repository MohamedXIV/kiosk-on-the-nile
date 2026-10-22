class_name DailyRoutine
extends RefCounted
signal slept(frame: Dictionary)
var clock: GameClock
var wallet: WalletService
var needs: NeedsService
var home: HomeService
var rent: int
var policy: MoodPolicy
var _last_rent_day: int
func _init(source_clock: GameClock, source_wallet: WalletService, source_needs: NeedsService, source_home: HomeService, daily_rent: int, mood_policy: MoodPolicy) -> void:
 clock = source_clock
 wallet = source_wallet
 needs = source_needs
 home = source_home
 rent = daily_rent
 policy = mood_policy
 _last_rent_day = clock.day
 clock.day_changed.connect(_day_changed)
func preview(hours: Variant) -> ActionResult:
 if not policy.valid_duration(hours): return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"invalid_sleep_duration")
 var extra := policy.oversleep_hours(needs.mood,needs.rest)
 var duration := int(hours)+extra
 var total := clock.minutes+duration*60.0
 return ActionResult.success({"requested_hours":int(hours),"extra_hours":extra,"actual_hours":duration,"wake_day":clock.day+floori(total/1440.0),"wake_minutes":fposmod(total,1440.0)})
func sleep(hours: int) -> ActionResult:
 var result := preview(hours)
 if not result.ok: return result
 var before := wallet.balance
 var frame := clock.elapse_minutes(float(result.details.actual_hours)*60)
 needs.recover_sleep(float(result.details.actual_hours),home.has_fan and home.fan_on)
 result.details["rent_spent"] = before-wallet.balance
 result.details["cue"] = "chime"
 slept.emit(frame)
 return result
func _day_changed(_previous: int, current: int) -> void:
 # Each calendar day is assessed once, even across a long sleep. No arrears.
 while _last_rent_day<current:
  _last_rent_day += 1
  if wallet.balance>=rent: wallet.try_spend(rent)
func snapshot() -> Dictionary:
 return {"last_rent_day":_last_rent_day}
func restore(data: Dictionary) -> ActionResult:
 if not ContentValidation.integer(data.get("last_rent_day")) or int(data.last_rent_day)!=clock.day: return ActionResult.failure(ActionResult.Code.INVALID_SAVE,&"invalid_rent_day")
 _last_rent_day = int(data.last_rent_day)
 return ActionResult.success()
