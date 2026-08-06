import 'package:flutter/widgets.dart';

/// Re-runs the entrance animations of [child] every time the surrounding tab
/// becomes active again.
///
/// Shell tabs (`StatefulShellRoute.indexedStack`) stay mounted when hidden,
/// with `TickerMode` disabled, so `flutter_animate` effects never replay on
/// revisit. This widget listens for the tab returning to the active state and
/// bumps a generation key, re-creating the subtree so its entrance animations
/// fire again on every visit while the screen's `State` is preserved.
class TabReveal extends StatefulWidget {
  const TabReveal({super.key, required this.child});

  final Widget child;

  @override
  State<TabReveal> createState() => _TabRevealState();
}

class _TabRevealState extends State<TabReveal> {
  int _generation = 0;
  bool _initialized = false;
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;

    // Skip the very first dependency pass so the initial active tab mounts
    // once (its animation plays naturally) instead of double-building.
    if (_initialized && active && !_wasActive) {
      setState(() => _generation++);
    }

    _initialized = true;
    _wasActive = active;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('tab-reveal-$_generation'),
      child: widget.child,
    );
  }
}
