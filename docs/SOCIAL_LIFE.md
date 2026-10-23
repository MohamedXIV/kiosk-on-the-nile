# Companionship and the workshop trial

This slice uses existing Farid and Youssef. Visitors remain independent of kiosk opening and purchases; no story action spawns an actor. The world stays quiet and capped at four people.

## Ownership

- `content/social_life.json`: invitation distance/wait, named social actions and their prerequisites, relationship moments/caps/stages, topic labels and trial scheduling.
- `content/stories/companionship.ink`: authored Egyptian Arabic speech, listening and explicit player choices. `effect:social\|action_id` selects a validated action, never a method name.
- `SocialLife`: semantic receipts, heard people, invitation timing, consents and the actual offscreen workshop activity. Its candidate action changes knowledge and directional relationships only after all candidates validate.
- `KnowledgeBook`: player facts with speaker/time provenance for new social disclosures. Legacy occurrence-only facts retain their old provenance.
- `RelationshipStore`: NPC→player familiarity/trust, separate from food quality/reputation. The notebook displays heard people and authored familiarity stages; unseen trial results stay private.

## The story

Spend time near either person or select specific topics through E. Get acquainted before personal disclosure. Learn Farid's workshop need and Youssef's search/study constraint in either order. Relay the opportunity and ask each whether they want direct contact and a trial. Both explicit consents are required.

After both current visits physically end, the two coordinate offscreen. The default appointment is next day16:00, lasting120 world minutes. Starting60 minutes before it, new visits by either participant are withheld. Existing visits/orders/choices remain intact: the actual trial starts once both have naturally left. Other people and the shared clock continue. Sleep uses the same activity interval and cannot award a second trial.

The player learns the appointment and result by hearing them, not from the world service automatically. Each person can describe the first day. Farid normally needs three afternoons; explicitly passing Youssef's two-day limit and agreeing with both allows a two-day week of trial work. This agreement can happen before or after the first actual trial. It is not permanent employment and adds no wages system.

## Authoring boundaries

Semantic actions are once-only; shared moment IDs prevent paying twice for the same referral in opposite directions. Familiarity/trust gains toward the player share an authored daily cap. Waiting next to someone, recall and repeat sales do not grant points. Silence only accepts the invitation to listen; it never accepts a work agreement. Declining or walking away leaves personal disclosure available.

The case is intentionally bounded, with a finite lifecycle and action IDs. Adding another independent story should add its own world owner or extend the explicit activity contract, rather than hiding world truth in Ink variables/player facts. Keep published compiled stories in the existing archive mechanism when changing a story with active save cursors.

## Persistence

Schema4/revision7 adds `social_life`. Revisions1–6 migrate with empty referrals and no invented trial. Existing orders, jobs, money, knowledge, relationships and Ink choices remain owned by their previous components. Candidate loading validates social dependencies and rejects impossible simultaneous workshop/corniche presence before installing a session.
