# Local patches over pinned upstream

Upstream commit remains pinned in `tools/dependencies.lock.json`.

## 2026-10-25: plain JSON string fast path

`runtime/ink_simple_json.gd`, `Reader.read_string`: locate the next quote and copy an unescaped string with native String operations instead of appending each Unicode character in GDScript. If a backslash precedes that quote, use the original upstream escape decoder. Numeric parsing, dictionary order, decoding errors and writer remain unchanged. This also accelerates Ink state reading through the shared reader.

Do not replace the reader with `JSON.parse_string` without addressing Ink integer/float type semantics. Do not overwrite this tracked patch when refreshing the upstream addon. The installer preserves the tracked addon when present.

Measured paired parser results and scope are recorded in `docs/notes/2026-10-25-stutter-first-pass.md`.
