## [0.1.5] - 2026-10-31 - Web compile fix

### Fixed
- `KvFeedbackHistoryStore` no longer fails to compile for the web: an integer literal larger than 2^53 in the event-time key was not representable in JavaScript. The key is unchanged for every date after the epoch; a date before the epoch is keyed as the epoch.

## [0.1.4] - 2026-10-30 - Feedback history and proposal stores, applying an approved proposal

### Added
- `FeedbackHistoryStore` and `ProposalStore` ports with in-memory defaults (`InMemoryFeedbackHistoryStore`, `InMemoryProposalStore`) and `KvStoragePort`-backed implementations (`KvFeedbackHistoryStore`, `KvProposalStore`). `PhilosophyEngine` takes them (and `historyLimit`) as optional constructor arguments, so feedback history and generated proposals can outlive the process. Defaults keep today's behavior, except that the history is bounded.
- Retention: `KvFeedbackHistoryStore(maxEvents: 500)` and `InMemoryFeedbackHistoryStore(maxEvents: 500)` drop the oldest events beyond the bound, and one `recent` reads at most that many values (Kv keys carry the event time, so the newest are chosen from the key list). `KvProposalStore(maxResolved: 200)` removes the oldest resolved proposals beyond the bound; `pending` and `approved` proposals are never removed.
- `PhilosophyEngine.applyProposal(id, {approvedBy})`: applies a human-approved `valuePriority` reinforce/weaken proposal as a new inactive derived ethos record (provenance `derived`, never an edit of the source, never activated here). Other proposal kinds throw `UnsupportedError`. `rejectProposal`, `listProposals` and the `philosophy.proposal_applied` / `philosophy.proposal_rejected` events complete the cycle.

### Changed (dependency floor)
- `mcp_bundle` floor raised to `^0.4.12`.

### Fixed
- `proposeFeedback` counted each new event twice (it was in the history and added again by the analysis), so two feedback events reached the documented minimum of three. A proposal now needs three events.

## [0.1.3] - 2026-07-09 - KvEthosStoreAdapter implements EthosStoreDelete

### Added
- **`KvEthosStoreAdapter` now also implements `EthosStoreDelete`** (mcp_bundle 0.4.6): `deleteEthos(id)` removes the record key and, when the deleted id was the active ethos, clears the active pointer (`getActiveEthosId` → null; no implicit succession). Idempotent — deleting an absent id is a no-op. Additive — the adapter's `EthosStorePort` surface is unchanged.

### Changed (dependency floor)
- `mcp_bundle` floor raised to `^0.4.6` (requires the `EthosStoreDelete` capability interface).

## [0.1.2] - 2026-06-23 - deterministic prohibition enforcement (forbiddenPatterns)

### Changed
- **`_detectViolation` now enforces `Prohibition.forbiddenPatterns` (mcp_bundle 0.4.4) first** — any declared forbidden pattern present (case-insensitive) in the proposed output/action is a deterministic violation. Previously the structural evaluator recognized **only two hardcoded NL statement shapes** (`'uncertain'`+`'certain'`, `'hide'`+`'limitation'`) and silently returned "not violated" for every other prohibition — so a real prohibition like "never output X" was never caught by `checkProhibitions` / the post-generation `intervene` gate (it fell open). `forbiddenPatterns` is the sound, LLM-free enforcement hook: an author / LLM declares the concrete strings that must never appear and the engine blocks them deterministically. The two built-in heuristics remain as a best-effort fallback; semantic judgment of arbitrary NL `statement`s is explicitly deferred to an LLM seam (spec `platform/12-flowbrain-runtime.md` §3). Test: `test/evaluation/philosophy_evaluator_test.dart` (forbiddenPatterns hard/soft + no-match).

### Changed (dependency floor)
- `mcp_bundle` `^0.4.0` → `^0.4.4` — uses `Prohibition.forbiddenPatterns`, introduced in 0.4.4; floored to guarantee it.

## [0.1.1] - 2026-05-23 - mcp_bundle 0.4.0 cascade

### Changed (cascade)
- `mcp_bundle` caret bumped from `^0.3.0` to `^0.4.0`. mcp_philosophy does not touch `UiSection.pages` directly, so this release is a caret-only cascade. Consumers should bump to `^0.1.1`.

## [0.1.0] - 2026-04-28 - Initial Release

### Added
- `PhilosophyEngine` — sole implementation of `mcp_bundle`'s `PhilosophyPort`.
- Philosophy evaluation, prohibition checking, pipeline intervention (pre / during / post stages), tension detection, and ethos evolution proposals.
- Dynamic state weighting integration.
- Re-exports of contract types from `mcp_bundle`.
