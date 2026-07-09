import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Unified branded loading indicator used across the whole app.
///
/// Renders the circular transfers arrows icon (`ic_nav_transfers`) rotating
/// continuously, replacing Flutter's default [CircularProgressIndicator].
/// Automatically picks the dark/light asset variant from the current theme
/// brightness.
///
/// - Leave [color] null to keep the icon's own brand two-tone (navy/green in
///   light, white/green in dark) — best for full-page/centered loaders.
/// - Pass [color] (e.g. [Colors.white]) for loaders sitting inside filled
///   buttons, where a single tint reads better against the button background.
class UffLoader extends StatefulWidget {
  const UffLoader({super.key, this.size = 32, this.color});

  /// Width/height of the spinner in logical pixels.
  final double size;

  /// Optional single tint. When null the icon keeps its brand two-tone colors.
  final Color? color;

  @override
  State<UffLoader> createState() => _UffLoaderState();
}

class _UffLoaderState extends State<UffLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suffix =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        'assets/icons/ic_nav_transfers_$suffix.svg',
        width: widget.size,
        height: widget.size,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
