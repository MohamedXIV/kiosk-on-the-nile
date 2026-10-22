@tool
class_name ActionResult
extends RefCounted
enum Code { OK, INSUFFICIENT_FUNDS, OUT_OF_STOCK, HANDS_BUSY, TOO_EARLY, INVALID_STAGE, WRONG_ORDER, NOT_AVAILABLE, INVALID_CHOICE, INVALID_CONTENT, INVALID_SAVE, IO_ERROR }
var ok: bool = false
var code: Code = Code.OK
var message_key: StringName
var details: Dictionary = {}
static func success(data: Dictionary = {}) -> ActionResult:
 var value := ActionResult.new()
 value.ok = true
 value.details = data
 return value
static func failure(error: Code, message: StringName, data: Dictionary = {}) -> ActionResult:
 var value := ActionResult.new()
 value.code = error
 value.message_key = message
 value.details = data
 return value
