class_name StationVapour
extends Node2D
var job: CookingJob
var data: Dictionary
var _elapsed: float = 0
var _phase: float = 0
var _particles: Array[Dictionary] = []
func _process(delta: float) -> void:
 _phase += delta
 _elapsed += delta
 if job and job.stage!=&"EMPTY" and _elapsed>=float(data.interval):
  _elapsed = 0
  _particles.append({"age":0.0,"offset":Vector2(sin(_phase*7)*7,0)})
 for particle in _particles: particle.age+=delta
 _particles = _particles.filter(func(p):return p.age<float(data.lifetime))
 queue_redraw()
func _draw() -> void:
 for particle in _particles:
  var age: float = particle.age
  var ratio := age/float(data.lifetime)
  draw_circle(particle.offset+Vector2(sin(age*5)*8,-age*float(data.rise_speed)),float(data.radius)*(1+ratio),Color(0.85,0.86,0.83,(1-ratio)*0.3))
