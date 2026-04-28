# MCP Philosophy

> **Positioning:** `mcp_philosophy` is an internal component of the MakeMind knowledge stack exposed through the `mcp_knowledge` facade. Application code should import `package:mcp_knowledge/mcp_knowledge.dart` — the symbols declared here are re-exported from there. Direct `package:mcp_philosophy/` imports remain valid for advanced or integration scenarios but are discouraged in product code.

The value-principle, judgment-direction, and ethos layer for the MakeMind Knowledge System. The sole `PhilosophyPort` implementation: `PhilosophyEngine`.

## Capabilities

- **Philosophy evaluation** — assess context against the active ethos.
- **Prohibition checking** — gate actions against ethos prohibitions.
- **Pipeline intervention** — apply philosophy guidance at pre / during / post generation stages.
- **Tension detection** — surface cross-layer value tensions.
- **Ethos evolution** — propose ethos changes from feedback loops.
- **Dynamic state weighting** — integrate state weights into philosophical judgment.

Contract types (`PhilosophyPort`, `EthosStorePort`, `EthosRecord`, etc.) are defined in `mcp_bundle` and re-exported here.

## Quick Start

```dart
import 'package:mcp_philosophy/mcp_philosophy.dart';

final engine = PhilosophyEngine(
  ethosStore: ethosStorePort,
  facts: factsPort,
);

final guidance = await engine.evaluate(context);
final prohibitionCheck = await engine.checkProhibitions(action, context);
```

## Support

- [Issue Tracker](https://github.com/app-appplayer/mcp_philosophy/issues)
- [Discussions](https://github.com/app-appplayer/mcp_philosophy/discussions)

## License

MIT — see [LICENSE](LICENSE).
