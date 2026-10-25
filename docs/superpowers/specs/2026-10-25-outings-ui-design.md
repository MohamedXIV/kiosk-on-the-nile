# Outings UI design

Continue the approved native Godot bilingual UI rollout: market/appliance/homeware shopping, travel status and visitor action sheets. Retain quiet independent visitors and continuous world time. No new gameplay, story branches, prices, stock, travel timing, knowledge, save schema or effects.

## Approach

Extend existing native sheets, stable source-guarded catalogs and SheetControls. Replacing the UI framework or altering commerce/narrative owners would add migration risk without helping this bounded presentation task. Inline implementation in existing isolated work checkout is the established user workflow; continue authorization covers this rollout and preview publication.

Shopping has a searchable offer list and selected-product details, quantity, explicit review total, explicit confirmation and return. Show stock, contents, footprint and capabilities. Preserve reviewed quotes across locale changes; changing selection/quantity/stock invalidates review. Purchases remain authoritative and idempotent in ShopService. Avoid per-frame full stock/receipt snapshots. Keep custom data labels with exact source guards.

Travel shows guarded destination, phase and remaining time plus the existing return action only when browsing. The existing active personal conversation hub keeps its continuous Ink conversation and receives localized speaker/topic labels and focusable buttons. The older standalone visitor sheet also retains heading, social topics, pending order, recall/talk/close, but normal gameplay currently routes through the hub; do not introduce a second interaction step. Translate presentation only: Ink narrative content outside existing bilingual coverage stays as authored; never simulate or replay speech when changing language. Retain actor identities and topic availability.

At960×540 and1280×720, provide scroll boundaries and wrapping focusable buttons; locale changes retain selection/query/quantity. Close does not pause the world or cancel work. Existing modal ownership and actual command eligibility remain authoritative.

## Acceptance and limits

Compile/import and exact Web exports; real browser mouse/keyboard for stock new game or genuine Continue, browsing/search/review/confirm/return and both languages/resolutions as reachable. No automated tests requested or run. One fresh final review, one material fix pass. Publish complete stock offline preview ZIP and source/artifact prerelease, verify downloaded SHA. Document reachable coverage and explicit gaps; no main merge.
