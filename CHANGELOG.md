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
