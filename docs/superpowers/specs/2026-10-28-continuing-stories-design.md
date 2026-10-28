# Continuing stories and relayed messages

User authorized logical-order execution after PR14, leaving home guests aside. Implementation proceeds inline using existing Godot4.7.2/GDScript/Ink/JSON. This is a bounded #5 batch, not a new population/seating system.

Two authored arcs extend existing Farid/Youssef acquaintances: Youssef's exam preparation and Farid repairing his old radio. Each has an opening and a follow-up on a later calendar day. The other character can ask after the absent person, without already knowing their private problem. The player may accept or postpone carrying the question, ask the subject after hearing their follow-up, then carry the reply back. Explicit topic labels name the source. No action claims a real exam grade, a physical radio item, job assignment, or unseen character knowledge.

Use existing SocialLife actions/receipts, KnowledgeBook provenance, personal topic hub and companionship Ink. Add optional per-action next-day dependencies, absent-subject availability and typed message metadata. Receipts store exact authored message endpoints and predecessor, validated on restore; facts cross-check their originating receipts. Delivery does not repeat knowledge or relationship gains. Existing workshop trial remains unchanged.

Alternatives considered: a second standalone message component would duplicate save/action/topic infrastructure; only authored strings would lack durable delivery evidence. Extend the existing action ledger, with focused validation helpers where useful. This choice is the implementer's judgment under the user's autonomous execution request.

Arabic/English ship together. Keep optional silence, no deadline/quest marker/arrival increase, no home guests, no navigation change. Save revision18 explicitly requires a new game for earlier saves; old files remain intact. No historical migrations/graphs or automated suites. Verify with content/Ink/localization/import/Web build and bounded native real-Ink observations, then independent review and a complete development preview. Integration of new PR is a separate concrete decision.
