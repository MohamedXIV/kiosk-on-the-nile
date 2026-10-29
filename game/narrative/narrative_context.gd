class_name NarrativeContext
extends RefCounted
## Stable actor identities are separate from ephemeral visit handles.
var topic_id: String
var roles: Dictionary = {}
var bindings: Dictionary = {}
var handles: Dictionary = {}
var stable_roles: Dictionary = {}
func resolve(value: Variant) -> Variant:
 if value is Dictionary:
  if value.size()==1 and value.has("role"):return roles.get(value.role)
  if value.size()==1 and value.has("binding"):return bindings.get(value.binding)
  if value.size()==1 and value.has("actor"):return value.actor
  var result := {}
  for key in value:
   var part: Variant=resolve(value[key])
   if part==null:return null
   result[key]=part
  return result
 if value is Array:
  var result: Array=[]
  for part in value:
   var resolved: Variant=resolve(part)
   if resolved==null:return null
   result.append(resolved)
  return result
 return value
func identity() -> Dictionary:
 return {"topic":topic_id,"bindings":bindings.duplicate(true),"roles":stable_roles.duplicate(true)}
static func bind(id: String, definition: Dictionary, values: Variant, presence_handles: Variant, schemas: Dictionary, resolver: Callable, turn: Dictionary = {}, saved_roles: Dictionary = {}) -> ActionResult:
 if not values is Dictionary or not presence_handles is Dictionary or not NarrativePolicyValidation.same_keys(values,definition.bindings):return _fail()
 var context := NarrativeContext.new();context.topic_id=id
 for key in values:
  if not NarrativePolicyValidation.typed(values[key],definition.bindings[key],schemas):return _fail()
 context.bindings=values.duplicate(true)
 for role in definition.roles:
  var actor: Variant=context.resolve(definition.roles[role])
  if not NarrativePolicyValidation.typed(actor,"actor",schemas):return _fail()
  context.roles[role]=actor
 context.stable_roles=context.roles.duplicate()
 if not saved_roles.is_empty() and context.stable_roles!=saved_roles:return _fail()
 for role in turn:
  if not role in definition.get("turn_roles",[]) or not NarrativePolicyValidation.typed(turn[role],"actor",schemas):return _fail()
  context.roles[role]=turn[role]
 for pair in definition.get("distinct_roles",[]):
  if context.roles[pair[0]]==context.roles[pair[1]]:return _fail()
 for role in presence_handles:
  if not context.roles.has(role) or not presence_handles[role] is String or not resolver.is_valid():return _fail()
  var actual: Variant=resolver.call(presence_handles[role])
  if not actual is Dictionary or actual.get("actor_id")!=context.roles[role]:return _fail()
 context.handles=presence_handles.duplicate()
 return ActionResult.success({"context":context})
static func _fail() -> ActionResult:
 return ActionResult.failure(ActionResult.Code.NOT_AVAILABLE,&"invalid_policy_bindings")
