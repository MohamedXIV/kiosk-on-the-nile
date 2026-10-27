# Web save acknowledgment — issue10

Source branch fix/web-save-durability from08ac183; no main merge. This corrective batch follows quiet-social preview706d7d0.

## Cause and decision
Godot4.7.2 `JavaScriptBridge.force_fs_sync()` requests a future asynchronous filesystem sync and does not expose its completion result to GDScript. SaveStore correctly replaces the native/MEMFS file but that immediate result did not prove browser durability. A bounded Chrome storage timeline retained the old checksum after the Save toast, then observed the new one; latency is not assumed constant.

Retain SaveStore as sole writer and preserve backup/restore/schema4/revision16. WebSaveAck uses standard readonly IndexedDB transactions against the pinned engine IDBFS layout (`/userfs`, `FILE_DATA`), with the actual globalized save path and exact serialized bytes. It acknowledges only after the matching read transaction completes, never on a fixed delay or merely on a successful file write. It never creates a missing backend (enumeration plus abort of unexpected upgrade). Unsupported layout, access errors and deadline failure report unconfirmed persistence. This adapter is version-coupled to4.7.2; engine upgrades must revalidate that contract. A new independent save database or engine bundle patch was deliberately avoided.

## User behavior and ownership
SaveCoordinator owns readiness/in-flight/coalesced requests and a single completion signal. A newer explicitly queued request prevents an intermediate older success. Web-only unload warning remains while requested persistence is unconfirmed, including errors and retries. Native writes retain synchronous results and previous-save backup. Browser/OS termination or explicitly overriding the browser's leave warning cannot be guaranteed.

A dedicated localized HUD row shows saving/unconfirmed state, so ordinary action toasts cannot hide it. Actual durable success removes the row and shows the normal saved toast. External `ui.save_feedback` validates timeout_seconds1–120 (default15) and poll_seconds0.05–2 (default0.1), with poll shorter than timeout. These are wall-clock observation limits, not a promised safe wait. No game clock/save revision/Ink changes.

## Evidence status
No automated gameplay suite added/run. Native bounded observation: transition deferral emitted no early completion; boundary Save matched requested checksum, second Save retained previous backup, revision16 restored successfully. Existing fixture teardown70 ObjectDB/21 resources recorded without a general leak claim. Draft build completed324 localization references, import and Web Release export. Browser failure/retry/navigation observations and final source review/export/delivery results are appended after execution.
