# Web save durability acknowledgment

Issue#10, authorized by the user's instruction to continue the next work. Small corrective scope; implementation decisions below are the implementer's calls, not new game-design approvals.

## Intent and evidence
Godot4.7.2 `OS_Web::force_fs_sync()` sets `idb_needs_sync`; its next main-loop pass calls the asynchronous filesystem sync. Neither the public GDScript method nor SaveStore's immediate result acknowledges browser persistence. Source references: godotengine/godot tag4.7.2-stable, platform/web/os_web.cpp lines74–84,263–265 and platform/web/js/libs/library_godot_os.js lines191–205,292–298. Existing native file replacement/backups are retained.

## Approaches and decision
- Fixed delay: cannot establish completion across devices/failures; rejected.
- New application-owned save database: avoids engine storage layout but adds a second save authority and migration; disproportionate for this fix.
- Read-only acknowledgment of the engine-owned persisted file: chosen. Isolate the pinned4.7.2 Emscripten IDBFS contract in a narrow Web adapter. Use standard IndexedDB readonly transactions, compare exact expected saved bytes, and acknowledge on transaction completion. No engine JS patch, callable gameplay bridge, new storage authority or background writer. Unsupported backend/error/timeout fails closed, never reports success. Future engine upgrades must revalidate this adapter's backend contract.

## Behavior and ownership
SaveStore owns validated file writes/backups. SaveCoordinator captures a coherent boundary snapshot and owns pending/in-flight/deferred requests. A WebSaveAck adapter owns browser observation and a beforeunload warning while durability is unconfirmed. A real completed acknowledgment releases that warning and emits success. Pending requests show persistent localized saving feedback; errors show unconfirmed-save feedback and permit retry. Repeated requests serialize/coalesce without concurrent saves or stale callbacks completing a newer request. Native writes remain synchronous and use their existing completion result. No save format/revision or Ink changes.

Timeout and polling cadence are external UI data with validated bounded defaults (15seconds,0.1seconds), measured in browser wall time rather than game time. Browser/OS shutdown or explicitly overriding its leave warning cannot be guaranteed; do not claim such guarantees. No arbitrary safe wait is presented. Actual stored bytes must match the requested snapshot; subsequent simulation continues independently.

## Acceptance and limits
Use bounded native observations/build-only gate and actual Chrome save, pending navigation warning, persisted-byte acknowledgment, rapid reload/Continue, repeated save, delayed/error acknowledgment and retry. A controlled browser fault fixture may delay/deny readonly observation, clearly labeled and never shipped. Preserve older-save Continue/backups. One fresh final review and one material fix pass. Publish one complete corrected preview on existing artifacts, update issue10 and integration status; keep source isolated pending acceptance. No automated gameplay suite without user request, no main merge.
