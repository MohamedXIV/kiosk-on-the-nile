# Building and placement corrections — 2026-10-23

Product source: `9543cd0219e2` (Godot Standard4.7.2). This is a preview of the approved building corrections, not acceptance of all game systems. [GAME_VISION](../GAME_VISION.md) remains authoritative; no visitor pacing or economy values were changed in this work.

## Changes

- Home room has a door in the right wall and no middle partition. The rooftop is walkable; its separate staircase is at[0,4.25]. Arrival from the corniche uses the staircase, while new games/sleep spawn inside.
- Kiosk and room use authored room cells/buildings for interior classification, floors, structural collision and roof visibility. Entering reveals that building; leaving restores its roof. Arrangement temporarily reveals the layout.
- Item placement policies are JSON data: interior/exterior/either and optional allowed locations. The whole rotated footprint, including mounted children, must comply. Existing collision/access/actor checks run again at confirmation.
- Click a rendered item to select it in arrangement, then click the grid for its destination. R rotates, Enter confirms, Esc exits; dropdowns remain for stored pieces and hosts. Walls/doors/rooms/buildings remain developer authoring only.
- Six initial counters, mounted kettle/griddle and fridge fit inside the kiosk. Customer service positions stay outside the service window independently of counter movement. A matching held order takes priority over furniture interaction; nearby conversation can use the secondary action when furniture is closer.
- Item panels are titled for the selected piece. The desk retains item put/take and care, with no new cooking capability. Recipes require knowledge, a permitted venue, a suitable first station and placed/enabled equipment for their steps. Ingredient shortages remain visible for eligible recipes. Old frozen jobs have a job-scoped compatibility path for retired desk preparation.
- Saves remain schema4, now revision5. A private migration retains valid custom placements, moves displaced compound units deterministically and protects active work/loaded surfaces. Safe idle storage is reported; impossible protected relocation rejects the candidate. IDs, contents, money, job timing, history and Ink snapshots are retained. Actor and journey-origin positions are repaired; displaced cleaning pauses with its progress retained.

## Evidence from this session

No automated tests were added or run. Ink compilation, Godot import and debug/release exports succeeded. Release export log contains no editor addon, tests, qualification scene or command bridge.

Ordinary mouse/keyboard review through HTTP observed:

- Right room door exit/re-entry, a closed door blocking movement until reopened, exterior roof returning and interior revealing.
- Home desk care panel without recipe catalogue.
- Grid selection by clicking the desk, specific Arabic interior-only rejection outside the room, rejection at a crossing footprint, successful move and rotation to cell[4,1]/rotation1. Arrangement reviewed at1280×720 and960×540.
- Genuine previous revision4 save continued during a returning purchase journey. Money38200, active tea workflow and shawarma batch `cook_2`/vessel `item_23` survived. The fridge relocated to[14,-5]; no item needed storage. The journey completed at its safe original pose. Paused floor-cleaning state and historical served-food evidence remained.
- Opened the existing spit job through normal interaction and sliced a remaining portion, yielding `item_26` with original job/technique evidence. Saved the migrated session and reloaded for revision5 continuation.

The fresh independent reviewer identified displaced-cleaning and customer-marker problems; both were fixed and the combined build passed. The reviewer hit a usage limit before providing a complete final report, so this is not a completed independent review. Remaining review was by the author.

## Acceptance still open

Interactive native editor UndoRedo/import/export, all adversarial placement/door races, a no-space protected migration rejection, legacy home preparation completion, suspended Ink choice in this new revision, new-window paid service/conversation and a complete fresh-game cooking cycle were not manually exercised in this pass. Default multi-day balance and the larger social-life redesign remain separate work. Build success is not evidence for these cases.

Release `9543cd0219e2` itself was opened over HTTP with default content: new game, right-side exit and roof restoration were observed at1280×720 and960×540. Revision5 Continue restored `item_26` and its original batch evidence. ZIP SHA256: `bf7f01382983d564cbe8e72eb591612db8ece30cd49cd35e4f275f5994da7208`.
