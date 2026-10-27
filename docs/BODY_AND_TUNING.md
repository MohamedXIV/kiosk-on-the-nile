# Body, time and balancing

The default speed is **one world minute per simulation second**: one hour takes one real minute; a full day takes24 minutes of focused play. Existing window-focus pause policy still applies. Closing the game does not simulate offline time.

## Owners and units

| Owner | Responsibility | Unit |
|---|---|---|
| GameClock | Calendar, deadlines, shared frame | world minutes + simulation seconds |
| TuningStore | Applied validated values and pending candidate | Explicit units in content/tuning.json |
| NeedsService | True hunger/rest/mood | points, decay per world minute |
| AlertnessService | Temporary stimulant focus, diminishing doses, finite recovery-cycle budget | world minutes |
| ActionPolicy | Pre-spend eligibility, stable refusal decisions, effort receipts | world minutes, source IDs |
| FatigueService | Selected next visual pulse | simulation seconds |
| RecipeWorkflow | Frozen quality/timing/resource contract | short physical steps use simulation delta × frozen presentation rate; long cold/batch heat uses calendar |

Default hunger decay6points/hour, rest4points/hour. The sign does not cause work effort. Actual preparation steps and completed cleaning/placement actions cost rest/mood once. Costs and finite action classes live in `content/action_policy.json`. Low mood retains the existing quality penalty. New work may be refused below mood20, probability0.2, cooldown30world minutes, at most2 newly refused opportunities/day. Repeated clicks on that opportunity do not reroll; loading preserves the decision.

Hunger blocks unnecessary effort below10 but never dialogue, cooking, eating, shopping or the return/sleep route. Focus is denied below10, with a true-rest floor3 that stimulants cannot bypass. Existing timed preparation and pending choices can finish; a personal chapter ends at its natural boundary before another focused topic can start. Short practical requests and order recall remain available.

Tea adds up to12temporary focus for90world minutes. Nearby doses within6hours multiply1/0.6/0.3/0.1/0. Aggregate focus boost is capped12; stimulant-active overlap is capped180world minutes in the recovery cycle. This conservative budget is used even before focus would otherwise be denied. Rest is never restored by tea. Sleep of at least4hours resets the cycle; shorter sleep accounts for the skipped active interval and preserves the remainder. Actual consumed item receipts ground doses; rejected save candidates cannot install a different diminishing order or lower spent budget.

Intermittent blur affects the world below HUD/captions only. Warning intervals5–10simulation seconds, severe2–5, bounded pulses. The menu accessibility control cycles normal/reduced/off visuals without changing fatigue eligibility. The HUD describes fatigue and its tooltip shows true rest versus effective focus.

## Change values without building

- With the game closed, edit safe defaults in the external `content/tuning.json` next to the Web build, then reload the page. `fields.<key>.default` is the authority for those whitelisted values. Editing executable behavior still needs a build.
- For the developer panel, set `dev_panel_enabled` to `true` in that external file and reload. Open it from the menu or F8. The release default is false. This panel contains no commands to alter current needs/items/jobs.
- Paste or import JSON, inspect it, then Apply. Export downloads the editor JSON in Web; the browser cannot write files in the server folder. Native export writes to user storage.
- Applied overrides persist locally. New games read local overrides; Continue restores the values captured with that save. Saving waits for pending tuning to resolve. An invalid candidate leaves the current values/state intact.
- Apply stages the whole candidate and changes it at the next simulation boundary. Current need amounts, calendar, active recipes/quality contracts and existing deadlines are not reset. `{}` returns defaults and clears name overrides.

Example partial override (omitted values return to authored defaults):

```json
{
  "values": {
    "clock_speed": 1,
    "hunger_decay": 0.1,
    "rest_decay": 0.06666666666666667,
    "blur_strength": 0.35
  },
  "names": {
    "amgad": "عم أمجد",
    "player": "أنا"
  }
}
```

The panel exposes all field bounds/units through its help tooltip. Identities, structural content and Ink are not live-editable. Historical journal names retain the name heard at that time; new lines use current display names.

Visitor arrival/stay/purchase residuals use world minutes. Historical serialized names such as `stay_seconds` and `max_wait_seconds` remain for compatibility; `time_domain` declares the actual unit. Each new visit freezes its maximum wait. Migration converts pre-revision9 residuals and their maximum wait once at the old2.5min/sec, preserving their world-calendar duration; movement and ambient caption readability remain simulation seconds.

Save schema4/revision9 preserves need amounts, money, inventory, existing Ink, job definitions/elapsed/quality and reservations. New stimulation/effort/refusal history starts empty on migration. Legacy daily rent remains until the separately approved accounts increment replaces it; this increment does not add a second rent assessment.
