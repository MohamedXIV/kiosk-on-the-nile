class_name Soundscape
extends Node
var _data: Dictionary
var _players: Dictionary = {}
var _targets: Dictionary = {}
var _cues: Dictionary = {}
var _muted: bool = false
func configure(data: Dictionary) -> void:
 _data = data.duplicate(true)
 for id in data.layers:
  var player := AudioStreamPlayer.new()
  player.stream = load(data.layers[id].path).duplicate()
  if player.stream is AudioStreamWAV:
   player.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
   player.stream.loop_begin=0
   player.stream.loop_end=roundi(player.stream.get_length()*player.stream.mix_rate)
  player.volume_db = -80
  add_child(player)
  _players[id] = player
  _targets[id] = 0.0
 for id in data.cues:
  var player := AudioStreamPlayer.new()
  player.stream = load(data.cues[id])
  add_child(player)
  _cues[id] = player
func present(location: StringName, cooking: CookingService, home: HomeService, items: ItemStore = null, spaces: SpaceService = null, workflow: RecipeWorkflow = null) -> void:
 var active_grill := false
 var active_tea := false
 for station_id in cooking.station_ids():
  var job := cooking.job(StringName(station_id))
  if job.recipe.rules_id==&"kebda" and job.stage!=&"EMPTY": active_grill=true
  if job.recipe.rules_id==&"tea" and job.stage in [&"HEATING",&"BREWING"]: active_tea=true
 var active_oven := false
 if workflow!=null:
  for job in workflow.snapshot().jobs.values():
   if job.status!="active" or job.location_id!=str(location):continue
   var step: Dictionary=job.definition.steps[int(job.step_index)]
   if step.kind in ["heat","batch_heat"] and job.get("heat_on",true):
    if step.capability in ["fry","griddle","roast_rotisserie"]:active_grill=true
    if step.capability=="bake":active_oven=true
 for id in _players:
  var gain := float(_data.layers[id].get(str(location)+"_gain",0))
  if id=="sizzle": gain= gain if active_grill else 0
  if id=="oven":gain=gain if active_oven else 0
  if id=="kettle": gain= gain if active_tea else 0
  if id=="fan": gain= gain if home.has_fan and home.fan_on else 0
  if id=="radio":
   gain=0.0
   if items!=null and spaces!=null:
    for radio in items.instances(&"radio"):
     var placement := spaces.placement(StringName(radio.id))
     if not placement.is_empty() and placement.location_id==str(location) and radio.attributes.get("enabled",false):gain=float(_data.layers[id].get(str(location)+"_gain",0))
  _targets[id] = 0.0 if _muted else gain
func play_action(result: ActionResult) -> void:
 if result.ok and not _muted and _cues.has(result.details.get("cue","")): _cues[result.details.cue].play()
func set_muted(value: bool) -> void:
 _muted = value
func _process(delta: float) -> void:
 for id in _players:
  var current := db_to_linear(float(_players[id].volume_db))
  var gain := lerpf(current,(0.0 if _muted else float(_targets[id])),1-exp(-delta*float(_data.fade_speed)))
  _players[id].volume_db = linear_to_db(maxf(gain,0.0001))
  if gain>0.0002 and not _players[id].playing and not _muted: _players[id].play()
  elif gain<=0.0002 and _players[id].playing: _players[id].stop()

func _exit_tree() -> void:
 for player in _players.values(): player.stop()
 for player in _cues.values(): player.stop()
 _players.clear()
 _cues.clear()
