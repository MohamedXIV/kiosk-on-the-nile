# Semantic policy runtime — foundation #21

Current activation: [#24 family conversion](semantic-families.md) supersedes the foundation-only status below:22/51 production encounters now use shared semantics. The original scope notes remain historical.

This is the runnable API for the foundation described by the [design contract](semantic-narrative.md), extended by [per-character knowledge#22](semantic-knowledge.md). The selected design examples include commentary, future actions and instances; they are not a runnable catalog. Production content conversion belongs to #24. All49 current production encounters retain their existing eligibility paths.

## Loading and compilation

An optional manifest section named `narrative_policies` supplies exactly these keys:

```json
{
  "contract_version": 1,
  "profiles": {},
  "policies": {},
  "fact_types": {},
  "topics": {}
}
```

An absent section means an empty catalog. `ContentValidation` validates it before loading; `SemanticNarrative.configure` compiles the immutable session catalog once. Content cannot register executable callbacks. The application supplies finite actor/recipe/location/fact catalogs, relationship axes, channels and domain/event signatures.

- A profile is a nonempty dictionary of named finite numeric fields in0..100000. Profiles are content data, with no engine category enum.
- A named policy has exactly `roles` (unique identifiers), `parameters` (parameter name to `"profile"`) and `requires` (rule AST). Calls use `{"op":"policy","id":"...","roles":{"partner":{"role":"guest"}},"parameters":{"gate":"profile_id"}}`. Numeric profile fields use `{"parameter":"gate","field":"familiarity"}`. Calls explicitly remap roles. Expansion rejects cycles, more than24 AST levels,256 expanded nodes or8 named expansion levels.
- A fact type maps named argument keys to catalog types, `string` or `number`. A knowledge term has `type` and exactly its declared `args`. No text matching or interpolation determines identity.
- A topic requires `bindings`, `roles` and `stages`; optional keys are `turn_roles`, `distinct_roles`, `choices` and `actions`. Bindings declare catalog types, `string`, `number` or `event`. Stable roles resolve actor literals or actor bindings. `distinct_roles` lists unequal stable-role pairs. `turn_roles` may declare `speaker` and `listener`, available only at choice/action evaluation.
- Stages require `start` and `continuation`; optional `offer` defaults to `start`. Choices/actions map stable authored identifiers to rules. Stage rules cannot depend on unavailable turn roles. `resume` evaluates continuation.

Actor refs are exactly `{"actor":"catalog_id"}`, `{"role":"role_id"}` or `{"binding":"binding_id"}`. Other typed inputs may be literals or binding refs. Unknown fields, operators, types, roles and profile references reject compilation. `NarrativeContext.bind` checks exact binding keys, actor catalogs, distinct roles and optional stable saved-role equality. Presence handles are separately checked against their actor identities; a returning visit can change its handle, never its actor.

## Operators and provider boundary

| Operator | Runnable fields besides `op` |
| --- | --- |
| `all`, `any` | nonempty `rules` array |
| `not` | `rule` |
| `relationship` | actor refs `from`, `to`; `axis`, `compare` (`>=`, `>`, `==`, `<=`, `<`), numeric `value` |
| `knowledge` | actor ref `knower`, typed `fact`, nonempty `provenance_kinds` (`initial`, `heard`, `relayed`, `observed`) |
| `acquaintance` | actor refs `observer`, `other`; nonnegative integer `calendar_days`, `shared_days` |
| `consent` | actor refs `grantor`, `recipient`; string `purpose`, string/ref `scope` |
| `domain`, `event` | finite registered `id`, typed exact `args` dictionary |
| `available` | nonempty actor-ref `actors` array, at most16 |
| `near` | `actors`, `channel` (`personal` or `hearing`) |
| `time_window` | inclusive minute-of-day `start`, `end`, ordered within0..1440 |
| `unused` | `scope` (`once`, `day`, `visit`, `evidence`), `actors`; `evidence` string/ref required for evidence scope |

The design's richer event chronology/receipt notation will map onto registered typed event signatures in its owner adapter; this foundation does not invent those receipts. Event bindings are bounded opaque identifiers, not proof that an event happened.

`NarrativePolicy.evaluate(context, stage, key="", explain=false)` returns `PolicyDecision`: `status`, `allowed`, ordered `reasons` containing stable `id` and AST `path`, plus optional `evidence`. Every logical child evaluates; invalid propagates even through `any(true, invalid)` and `not(invalid)`. An absent valid fact is blocked. Normal/explain permissions agree. Providers return allowed/blocked/invalid and optional reason/evidence; missing or malformed providers are invalid. Decisions do not mutate owners. Calls/nodes/elapsed microseconds are observable; no cross-frame Boolean cache exists.

Read-only providers query directional RelationshipStore, GameClock, current presence/poses, kiosk state and recipe-learning state. `near` follows current distance/location channels (personal3.4 units or configured hearing radius), without introducing a visibility model. Knowledge#22 queries canonical per-knower assertions/provenance. The explicit `legacy_player_fact` signature `{"id":"fact"}` remains player-only for attributed initial/heard legacy evidence. It never reads player knowledge for an NPC. [Social memory#23](semantic-social.md) supplies actual introduction/shared-day, exact consent, scoped unused and finite social-event providers. Unknown event adapters still fail closed. No new production knowledge seeds are fabricated.

## Opt-in lifecycle and Ink

An encounter opts in with `semantic_topic` and exact `semantic_bindings`. Binding values are typed literals or `{"participant":0}` for actor bindings. Participant indexes are bounded0..15 and resolve to stable catalog actors. Nonempty legacy requires/offer_requires/choice_conditions and legacy topics/social_topic are rejected on converted encounters. Existing scheduling, pending-order, venue and physical interaction constraints still apply.

Menus evaluate offer; opening evaluates start before and after asynchronous Ink loading. Active continuation, choices and consequential hearing actions query current owners again. Start evaluation has no effects. A consumed start rule is not repeated after its own teaching effect. An optional `context_extra.semantic_start` stores catalog identity, concrete topic/bindings/roles, episode, start time, participant actors and an actual heard Journal or canonical semantic receipt. Current restore/paused validation verifies that identity and receipt; actor return rebinds presence without replay. NPC-only semantic evidence does not claim player hearing. No envelope/schema/revision change or migration is added; all unconverted records omit this metadata.

Ink choices declare literal `policy_choice:stable_id`; effect-bearing speech declares `policy_action:stable_id`. IDs must be valid identifiers, and choices in a frame must be unique. InkRuntime scans literal compiled choice tags into a target-path map and verifies emitted/restored choices against that source map: the current inkgd save representation does not retain choice tags. Dynamic/ambiguous stable tags fail closed. Compiled Ink details remain inside this adapter; third-party inkgd is unchanged.

Automatic choices use the same filtered candidates. An unguarded autonomous Ink jump cancels an opted-in conversation; authored guarded fallbacks remain content work. A semantic beat permits one `effect:semantic|action` tag containing a prepared knowledge-only batch. Legacy, mixed/world/domain mutations reject until their explicit prepared adapters exist. Effects require actual attributed speech/action permission and independent intended-listener hearing; no unheard opening teaches. Production content has not been partially converted to this adapter.

## Handoff

#22 supplies per-knower canonical assertions/provenance; #23 extends atomic publication to SocialLife history/consent and directional score candidates. They extend providers, not character-specific evaluator branches. #24 converts complete topic families, supplies explicit player/domain adapters and authors guarded leaving/fallback paths. #25 adds authoring diagnostics/tooling. #26 provides integrated acceptance; #27 alone records final save/version/changelog decisions and publishes the coherent preview.
