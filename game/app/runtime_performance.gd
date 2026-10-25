class_name RuntimePerformance
extends RefCounted
## Explicitly enabled observation; no game commands or per-frame state snapshots.
static var enabled: bool=false
static var _spans: Dictionary={}
static var _slow: Array=[]
static var _previous_frame: int=0
static var _report_at: int=0
static var _window_started: int=0
static func configure() -> void:
 enabled="--profile-performance" in OS.get_cmdline_user_args()
 if OS.has_feature("web"):
  enabled=str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('profile')"))=="1"
 _spans.clear();_slow.clear();_previous_frame=0
 _window_started=Time.get_ticks_usec()
 _report_at=_window_started+10000000
 if enabled:print("KIOSK_PERF enabled; reports every 10 seconds")
static func begin() -> int:
 return Time.get_ticks_usec() if enabled else 0
static func finish(label: String, started: int) -> void:
 if enabled and started>0:observe(label,Time.get_ticks_usec()-started)
static func observe(label: String, microseconds: int) -> void:
 if not enabled:return
 if not _spans.has(label):
  if _spans.size()>=64:return
  _spans[label]={"count":0,"total_us":0,"max_us":0,"over_16ms":0,"over_50ms":0,"over_100ms":0,"over_250ms":0}
 var record: Dictionary=_spans[label]
 record.count+=1;record.total_us+=microseconds;record.max_us=maxi(record.max_us,microseconds)
 for threshold in [16,50,100,250]:
  if microseconds>threshold*1000:record["over_%dms" % threshold]+=1
 if microseconds>50000:
  if _slow.size()>=32:_slow.pop_front()
  _slow.append({"span":label,"us":microseconds,"at_us":Time.get_ticks_usec()})
static func frame() -> void:
 if not enabled:return
 var now := Time.get_ticks_usec()
 if _previous_frame>0:observe("frame_interval",now-_previous_frame)
 _previous_frame=now
 if now<_report_at:return
 print("KIOSK_PERF ",JSON.stringify({"window_seconds":float(now-_window_started)/1000000.0,"spans":_spans,"recent_slow":_slow}))
 _spans.clear();_slow.clear();_window_started=now;_report_at=now+10000000
