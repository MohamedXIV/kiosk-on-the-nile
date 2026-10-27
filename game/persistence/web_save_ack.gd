class_name WebSaveAck
extends Node
## Read-only acknowledgment of Godot 4.7.2's IDBFS backend; never a save writer.
## Revalidate this pinned backend contract when upgrading the Web export engine.
signal completed(result: ActionResult)
var _bridge: JavaScriptObject
var _callback: JavaScriptObject
const SCRIPT := """
(() => {
 if (globalThis.__kioskSaveAckV1) return;
 const host = {dirty: false, cancel: null};
 host.arm = () => { host.dirty = true; };
 globalThis.addEventListener('beforeunload', event => {
  if (!host.dirty) return;
  event.preventDefault(); event.returnValue = '';
 });
 host.begin = (path, expected, timeoutMs, intervalMs, callback) => {
  if (host.cancel) host.cancel();
  host.dirty = true;
  let done = false, db = null, poll = null, deadline = null;
  const finish = status => {
   if (done) return;
   done = true; clearTimeout(poll); clearTimeout(deadline);
   if (db) db.close();
   host.cancel = null;
   if (status === 'confirmed') host.dirty = false;
   const report = callback; callback = null; expected = null;
   report(status);
  };
  host.cancel = () => {
   done = true; clearTimeout(poll); clearTimeout(deadline);
   if (db) db.close();
   callback = null; expected = null;
   host.cancel = null;
  };
  deadline = setTimeout(() => finish('timeout'), timeoutMs);
  const observe = () => {
   if (done) return;
   try {
    const transaction = db.transaction('FILE_DATA', 'readonly');
    const request = transaction.objectStore('FILE_DATA').get(path);
    let matched = false;
    request.onsuccess = () => {
     try {
      const bytes = request.result?.contents;
      matched = !!bytes && new TextDecoder('utf-8', {fatal: true}).decode(bytes) === expected;
     } catch (_) { finish('storage_error'); }
    };
    transaction.oncomplete = () => {
     if (done) return;
     if (matched) finish('confirmed');
     else poll = setTimeout(observe, intervalMs);
    };
    transaction.onabort = transaction.onerror = () => finish('storage_error');
   } catch (_) { finish('storage_error'); }
  };
  (async () => {
   try {
    if (!globalThis.indexedDB?.databases || !path.startsWith('/userfs/')) return finish('unavailable');
    const databases = await indexedDB.databases();
    if (done) return;
    if (!databases.some(entry => entry.name === '/userfs')) return finish('unavailable');
    const request = indexedDB.open('/userfs');
    // Never create a missing backend if it disappeared after enumeration.
    request.onupgradeneeded = () => { request.transaction.abort(); finish('unavailable'); };
    request.onerror = () => finish('storage_error');
    request.onblocked = () => finish('storage_error');
    request.onsuccess = () => {
     if (done) { request.result.close(); return; }
     db = request.result;
     db.onversionchange = () => finish('storage_error');
     if (!db.objectStoreNames.contains('FILE_DATA')) return finish('unavailable');
     observe();
    };
   } catch (_) { finish('storage_error'); }
  })();
 };
 host.dispose = () => { if (host.cancel) host.cancel(); };
 globalThis.__kioskSaveAckV1 = host;
})();
"""
func _ensure_bridge() -> bool:
 if not OS.has_feature("web"):return false
 if _bridge==null:
  JavaScriptBridge.eval(SCRIPT)
  _bridge=JavaScriptBridge.get_interface("__kioskSaveAckV1")
  _callback=JavaScriptBridge.create_callback(_on_observed)
 return _bridge!=null
func arm() -> void:
 if _ensure_bridge():_bridge.arm()
func begin(path: String, expected: String, settings: Dictionary) -> void:
 if not _ensure_bridge():
  _on_observed(["unavailable"])
  return
 _bridge.begin(path,expected,int(float(settings.get("timeout_seconds",15))*1000),int(float(settings.get("poll_seconds",0.1))*1000),_callback)
func _on_observed(arguments: Array) -> void:
 var status := str(arguments[0]) if arguments.size()==1 else "storage_error"
 if status=="confirmed":completed.emit(ActionResult.success({"durable":true}))
 else:completed.emit(ActionResult.failure(ActionResult.Code.IO_ERROR,&"web_save_unconfirmed",{"stage":"web_ack","reason":status}))
func _exit_tree() -> void:
 if _bridge!=null:_bridge.dispose()
