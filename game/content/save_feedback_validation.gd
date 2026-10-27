class_name SaveFeedbackValidation
extends RefCounted
static func validate(bundle: Dictionary) -> ActionResult:
 var ui: Dictionary=bundle.get("ui",{})
 if not ui.has("save_feedback"):return ActionResult.success()
 var data: Variant=ui.save_feedback
 if not data is Dictionary or not ContentValidation.bounded(data.get("timeout_seconds"),1,120) or not ContentValidation.bounded(data.get("poll_seconds"),0.05,2) or data.poll_seconds>=data.timeout_seconds:return ContentValidation.fail("ui.save_feedback")
 return ActionResult.success()
