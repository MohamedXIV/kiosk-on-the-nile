# Remote branch integration audit

Read-only inventory, 2026-10-27. No remote branches deleted or merged.

Actual remote branch count: 66. Main is an ancestor of the current source; before this documentation, current work was 123 commits ahead with zero main-only commits.

Artifact branches may have unrelated/orphan histories and are referenced by pinned download URLs. Preserve their commits and release references; do not merge them into main. Source branches covered by current work are potential later cleanup candidates only after source integration and release-dependency review. Uncovered branches require individual inspection.

| Branch | SHA | In current source | In main | Kind |
|---|---|---|---|---|
| `build/accounts-930c928` | `e506662e0b5f` | False | False | artifact — preserve |
| `build/body-clock-2fd6048` | `798317021c4d` | False | False | artifact — preserve |
| `build/body-clock-5c89ec0` | `5e9fddef6f50` | False | False | artifact — preserve |
| `build/body-clock-8d0a1a3` | `d1fa5283cedd` | False | False | artifact — preserve |
| `build/buildings-9543cd0` | `461440728c2c` | False | False | artifact — preserve |
| `build/character-life-c1c7997` | `2d69935e3ee7` | False | False | artifact — preserve |
| `build/companionship-669f9de` | `0be260b6a0ce` | False | False | artifact — preserve |
| `build/companionship-ed5153d` | `1bdb8b789332` | False | False | artifact — preserve |
| `build/dialogue-journal-7e3818d` | `986c3e9ce3b9` | False | False | artifact — preserve |
| `build/dynamic-seating-2ab7f73` | `171779074465` | False | False | artifact — preserve |
| `build/hud-c2dae7d` | `363f8cf3ac47` | False | False | artifact — preserve |
| `build/hud-icons-1316423` | `a574a0c27cbf` | False | False | artifact — preserve |
| `build/independent-visits-b97b532` | `0e92d0640320` | False | False | artifact — preserve |
| `build/items-a07aedb` | `3ac3faccfe70` | False | False | artifact — preserve |
| `build/items-a338d83` | `a8f4380b063c` | False | False | artifact — preserve |
| `build/living-spaces-3a07e8d` | `d5bbea87219c` | False | False | artifact — preserve |
| `build/living-spaces-f865d16` | `d047b26c06f0` | False | False | artifact — preserve |
| `build/local-avoidance-d17a497` | `45c4474eb3a4` | False | False | artifact — preserve |
| `build/localization-0ea4572` | `c70f3e585aec` | False | False | artifact — preserve |
| `build/localization-4e3876d` | `f0a1c8565f0d` | False | False | artifact — preserve |
| `build/localization-67e8e69` | `19ea3c18f021` | False | False | artifact — preserve |
| `build/notebook-420cfe0` | `18ff8586abd3` | False | False | artifact — preserve |
| `build/outings-07bb9a1` | `aa0893d129bc` | False | False | artifact — preserve |
| `build/outings-bf5d8f7` | `65a8f188b0ab` | False | False | artifact — preserve |
| `build/performance-1f090e8` | `4e4429cff57d` | False | False | artifact — preserve |
| `build/performance-f5da764` | `6b80e0011c50` | False | False | artifact — preserve |
| `build/prompts-46a26af` | `9df91c1173c8` | False | False | artifact — preserve |
| `build/spatial-awareness-8fa96b5` | `12dcdaa4fb57` | False | False | artifact — preserve |
| `build/stability-e9b816d` | `fe5804fe99a3` | False | False | artifact — preserve |
| `build/supplier-38396bb` | `d44d4c0521c0` | False | False | artifact — preserve |
| `godot-preview-2026-10-22-933f1b7` | `9efef633c4f7` | False | False | source |
| `godot-preview-dialogue-fix-6dcb784` | `8acdf378701a` | False | False | source |
| `godot-preview-sleep-mood-8754ac5` | `e087b2d0ace5` | False | False | source |
| `godot-preview-sleep-mood-8b4b033` | `4f0161d10772` | False | False | source |
| `godot-preview-social-hud-c752382` | `ab2be380d1b3` | False | False | source |
| `main` | `705de5ace833` | True | True | source |
| `preview/accounts-930c928` | `d26b1d191216` | True | False | source |
| `preview/body-clock-2fd6048` | `981b41a94b80` | True | False | source |
| `preview/body-clock-5c89ec0` | `5c89ec0d7aab` | True | False | source |
| `preview/body-clock-8d0a1a3` | `8d0a1a3f60d1` | True | False | source |
| `preview/buildings-9543cd0` | `af1aeace725c` | True | False | source |
| `preview/character-life-c1c7997` | `1fbbf6dc3a41` | True | False | source |
| `preview/companionship-669f9de` | `bdd6dff6e73c` | True | False | source |
| `preview/companionship-ed5153d` | `ed5153deaef9` | True | False | source |
| `preview/dialogue-journal-7e3818d` | `a8e158e78863` | True | False | source |
| `preview/dynamic-seating-2ab7f73` | `d52364496a5d` | True | False | source |
| `preview/hud-c2dae7d` | `ed7ded4e0464` | True | False | source |
| `preview/hud-icons-1316423` | `621b9a0a5e13` | True | False | source |
| `preview/independent-visits-b97b532` | `962bd135e985` | True | False | source |
| `preview/items-a07aedb` | `30e37816256d` | True | False | source |
| `preview/items-a338d83` | `a338d8308a0a` | True | False | source |
| `preview/living-spaces-3a07e8d` | `3a07e8d08ead` | True | False | source |
| `preview/living-spaces-f865d16` | `f865d16057f5` | True | False | source |
| `preview/local-avoidance-d17a497` | `344b533191c1` | True | False | source |
| `preview/localization-0ea4572` | `03f9391edd55` | True | False | source |
| `preview/localization-4e3876d` | `4e3876d6b352` | True | False | source |
| `preview/localization-67e8e69` | `67e8e694dff0` | True | False | source |
| `preview/notebook-420cfe0` | `87c6e0df5043` | True | False | source |
| `preview/outings-07bb9a1` | `ed615764c450` | True | False | source |
| `preview/outings-bf5d8f7` | `bf5d8f73f742` | True | False | source |
| `preview/performance-1f090e8` | `c8719e863998` | True | False | source |
| `preview/performance-f5da764` | `abf3a11d0bb1` | True | False | source |
| `preview/prompts-46a26af` | `7e601cef9341` | True | False | source |
| `preview/spatial-awareness-8fa96b5` | `badc9cf5d2f6` | True | False | source |
| `preview/stability-e9b816d` | `5c75714471ac` | True | False | source |
| `preview/supplier-38396bb` | `70d035f05145` | True | False | source |

## Integration gate

1. Review this source integration PR against main, including migrations, build/export configuration and published content.
2. Run only the checks explicitly authorized for integration; no gameplay suite was run for this documentation audit.
3. Obtain approval to merge the concrete PR.
4. Prepare a separate exact branch-deletion list, with pinned artifact/release reachability checked. Approval of a source merge is not approval to delete release branches.

## Source branches not contained in current work

- `godot-preview-2026-10-22-933f1b7`: current-only / branch-only commit counts `115	1`. Keep pending inspection; do not infer obsolete from its name.
- `godot-preview-dialogue-fix-6dcb784`: current-only / branch-only commit counts `114	1`. Keep pending inspection; do not infer obsolete from its name.
- `godot-preview-sleep-mood-8754ac5`: current-only / branch-only commit counts `112	1`. Keep pending inspection; do not infer obsolete from its name.
- `godot-preview-sleep-mood-8b4b033`: current-only / branch-only commit counts `113	1`. Keep pending inspection; do not infer obsolete from its name.
- `godot-preview-social-hud-c752382`: current-only / branch-only commit counts `111	1`. Keep pending inspection; do not infer obsolete from its name.
