## [0.1.1] - 2026-05-23 - mcp_bundle 0.4.0 cascade

### Changed (cascade)
- `mcp_bundle` caret bumped from `^0.3.0` to `^0.4.0`. mcp_philosophy does not touch `UiSection.pages` directly, so this release is a caret-only cascade. Consumers should bump to `^0.1.1`.

## [0.1.0] - 2026-04-28 - Initial Release

### Added
- `PhilosophyEngine` — sole implementation of `mcp_bundle`'s `PhilosophyPort`.
- Philosophy evaluation, prohibition checking, pipeline intervention (pre / during / post stages), tension detection, and ethos evolution proposals.
- Dynamic state weighting integration.
- Re-exports of contract types from `mcp_bundle`.
