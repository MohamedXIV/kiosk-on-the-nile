class_name InkPlayerCache
extends Node
## Session-owned idle players, never shared by live conversations or persisted.
const MAX_IDLE := 8
var _idle: Dictionary={}
var _order: Array[String]=[]
var _leased: Dictionary={}
func checkout(key: String) -> Node:
 var player: Node=_idle.get(key)
 if player==null:return null
 _idle.erase(key);_order.erase(key)
 _leased[player.get_instance_id()]=key
 return player
func attach(player: Node, key: String) -> void:
 add_child(player)
 _leased[player.get_instance_id()]=key
func release(player: Node, healthy: bool) -> void:
 var id := player.get_instance_id()
 if not _leased.has(id):return
 var key: String=_leased[id]
 _leased.erase(id)
 if not healthy or not is_inside_tree() or _idle.has(key):
  player.destroy();player.queue_free()
  return
 _idle[key]=player;_order.append(key)
 while _order.size()>MAX_IDLE:
  var oldest: String = _order.pop_front()
  var evicted: Node=_idle[oldest]
  _idle.erase(oldest)
  evicted.destroy();evicted.queue_free()
